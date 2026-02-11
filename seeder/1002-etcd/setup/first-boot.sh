#!/bin/bash
set -euo pipefail

COMMAND=${1:-}
shift
SETUP_DIR=/root/setup
ETCD_PKI_DIR=/etc/etcd/pki
ETCD_CONF_TEMPLATE="$SETUP_DIR/etcd.conf"
LOG_FILE=/root/setup.log
SIGNER_IP=""
IP=$(ip -4 addr show dev eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
echo "Detected appliance IP: $IP" >> "$LOG_FILE"

parse_opts() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --signer-ip=*)
        SIGNER_IP="${1#*=}"
        ;;
      --signer-ip)
        [[ $# -ge 2 ]] || { echo "--signer-ip requires a value"; exit 1; }
        SIGNER_IP="$2"
        shift
        ;;
      *)
        echo "unknown option: $1"
        exit 1
        ;;
    esac
    shift
  done
}

case "$COMMAND" in
  init|join)
    parse_opts "$@"
    ;;
    *)
    echo "Unknown command: $COMMAND"
    exit 1
    ;;
esac

mkdir -p "$ETCD_PKI_DIR"
mkdir -p "$(dirname "$LOG_FILE")"
echo "==== First-boot started at $(date) with $COMMAND option ====" >> "$LOG_FILE"


if [[ "$COMMAND" == "init" ]]; then
  systemctl stop etcd >> "$LOG_FILE" 2>&1
  echo "Stopped etcd service" >> "$LOG_FILE"
  rm -rf /var/lib/etcd/*

  LISTEN_URL=$(grep -oP '(?<=^ETCD_LISTEN_CLIENT_URLS=).*' /etc/default/etcd || true)

  if [[ "$LISTEN_URL" != '"http://127.0.0.1:2379"' ]]; then
      echo "Detected injected etcd config, skipping bootstrap" >> "$LOG_FILE"
      rm -rf "$SETUP_DIR"
      echo "Removed setup directory" >> "$LOG_FILE"
      exit 0
  fi
  echo "No injected conf detected, proceeding with bootstrap" >> "$LOG_FILE"

  echo "Generating ca.key" >> "$LOG_FILE"
  openssl genrsa -out "$ETCD_PKI_DIR/ca.key" 4096
  chown root:signer "$ETCD_PKI_DIR/ca.key"
  chmod 0640 "$ETCD_PKI_DIR/ca.key"
  echo "Generating ca.crt" >> "$LOG_FILE"
  openssl req -x509 -new -nodes -key "$ETCD_PKI_DIR/ca.key" -sha256 -days 3650 -out "$ETCD_PKI_DIR/ca.crt" -subj "/CN=etcd-builder-CA" 
  echo "Generating server.key" >> "$LOG_FILE"
  openssl genrsa -out "$ETCD_PKI_DIR/server.key" 2048
  chown root:signer "$ETCD_PKI_DIR/server.key"
  chmod 0640 "$ETCD_PKI_DIR/server.key"
  echo "Generating server.csr" >> "$LOG_FILE"
  openssl req -new -key "$ETCD_PKI_DIR/server.key" -out "$ETCD_PKI_DIR/server.csr" -subj "/CN=etcd-bootstrap" -addext "subjectAltName=DNS:$HOSTNAME,IP:$(hostname -I | awk '{print $1}')" -addext "keyUsage=critical,digitalSignature,keyEncipherment"  -addext "extendedKeyUsage=serverAuth,clientAuth"
  echo "Generating server.crt" >> "$LOG_FILE"
  openssl x509 -req -in "$ETCD_PKI_DIR/server.csr" -CA "$ETCD_PKI_DIR/ca.crt" -CAkey "$ETCD_PKI_DIR/ca.key" -CAcreateserial -out "$ETCD_PKI_DIR/server.crt" -days 3650 -sha256 -copy_extensions copy
  echo "Generated unique appliance certificate signed by CA" >> "$LOG_FILE"

  sed "s/127.0.0.1/$IP/g;s/default/$HOSTNAME/g" "$ETCD_CONF_TEMPLATE" > /etc/default/etcd
  echo "Copied etcd.conf template and replaced IP" >> "$LOG_FILE"

  systemctl restart etcd >> "$LOG_FILE" 2>&1
  echo "Restarted etcd service" >> "$LOG_FILE"

  echo "Generating etcd client key file..." >> "$LOG_FILE"
  openssl req -new -newkey rsa:2048 -nodes -keyout $ETCD_PKI_DIR/signer.key -out $ETCD_PKI_DIR/signer.csr -subj "/CN=kube-apiserver-etcd-client"
  chown root:signer "$ETCD_PKI_DIR/signer.key"
  chmod 0640 "$ETCD_PKI_DIR/signer.key"
  chown root:root $ETCD_PKI_DIR/signer.csr
  chmod 0600 $ETCD_PKI_DIR/signer.csr

  echo "Generating gloabl etcd client certificate..." >> "$LOG_FILE"
  cat > "$ETCD_PKI_DIR/clientext.txt" <<EOF
basicConstraints = critical,CA:FALSE
keyUsage = digitalSignature
extendedKeyUsage = clientAuth
EOF

  # ici je crée le certificat initial
  openssl x509 \
    -req \
    -in "$ETCD_PKI_DIR/signer.csr" \
    -CA "$ETCD_PKI_DIR/ca.crt" \
    -CAkey "$ETCD_PKI_DIR/ca.key" \
    -CAcreateserial \
    -out "/authority/etcdclient.crt" \
    -days "1" \
    -extfile "$ETCD_PKI_DIR/clientext.txt"

  rm -rf "$SETUP_DIR"
  echo "Removed setup directory" >> "$LOG_FILE"
  echo "==== First-boot completed at $(date) ====" >> "$LOG_FILE"

  echo "First-boot finished successfully. See $LOG_FILE for details."
  echo
  echo "You can now join any number of etcd member running the following command on each as root:"
  echo "  ./setup/first-boot.sh join --signer-ip $IP"
  rm -rf /root/setup
fi

if [[ "$COMMAND" == "join" ]]; then
  systemctl stop etcd >> "$LOG_FILE" 2>&1
  echo "Stopped etcd service" >> "$LOG_FILE"
  rm -rf /var/lib/etcd/*

  echo "Generating server.key" >> "$LOG_FILE"
  openssl genrsa -out "$ETCD_PKI_DIR/server.key" 2048
  echo "Generating server.csr" >> "$LOG_FILE"

  if [ -z "$SIGNER_IP" ]; then
    echo "[$(date '+%F %T')] ERROR: SIGNER_IP is unset !" >&2
    exit 1
  fi
  ssh signer@$SIGNER_IP "get-certificate" > "$ETCD_PKI_DIR/ca.crt"
  TOPOLOGY="$(ssh signer@$SIGNER_IP get-topology),$HOSTNAME=https://$(hostname -I | awk '{print $1}'):2380"
  openssl req -new -newkey rsa:2048 -nodes -keyout "$ETCD_PKI_DIR/server.key" -out "$ETCD_PKI_DIR/server.csr" -subj "/CN=etcd-bootstrap"
  echo "Requesting server.crt to $SIGNER_IP..." >> "$LOG_FILE"
  base64 < "$ETCD_PKI_DIR/server.csr" | ssh signer@$SIGNER_IP "$HOSTNAME=$(hostname -I | awk '{print $1}')" > "$ETCD_PKI_DIR/server.crt"
  sed \
    -e "s|^ETCD_INITIAL_CLUSTER=.*|ETCD_INITIAL_CLUSTER=\"$TOPOLOGY\"|" \
    -e "s/127.0.0.1/$(hostname -I | awk '{print $1}')/g" \
    -e "s/default/$HOSTNAME/g" \
    -e "s/new/existing/g" \
    "$ETCD_CONF_TEMPLATE" > /etc/default/etcd
  systemctl start etcd
  rm -rf /root/setup
fi