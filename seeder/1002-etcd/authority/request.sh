#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
PATH=/usr/sbin:/usr/bin:/sbin:/bin
ulimit -f 64
ulimit -m 262144
ulimit -d 262144
ulimit -t 7
ulimit -u 32
umask 077

ETCD_PKI_DIR=/etc/etcd/pki
CA_CERT="$ETCD_PKI_DIR/ca.crt"
CA_KEY="$ETCD_PKI_DIR/ca.key"
DAYS_VALID=1

usage() {
  cat <<'EOF'

etcd authority request interface
--------------------------------

This endpoint is intended to be executed over SSH by the restricted
"signer" account. The requested operation is determined by the SSH
original command.

Available commands:

  get-certificate
      Returns the current etcd Certificate Authority (CA) certificate.

  get-peers
      Returns the list of etcd client endpoints currently registered
      in the cluster.

  get-topology
      Returns the etcd initial cluster topology string in the format:
      <name>=<peerURL>,...

  kubemaster-<id>
      Returns the shared kube-apiserver etcd client certificate.
      No CSR is required.

  etcd-<name>=<ipv4>
      Signs a provided base64-encoded CSR from stdin and returns a
      server certificate for a new etcd member. Also registers the
      member in the cluster.

  sign-clientcert
      Regenerates the shared kube-apiserver etcd client certificate.
      Intended for local root execution only.

  --help
      Displays this help message.

Notes:
  - Input validation is strictly enforced.
  - CSR input must be base64-encoded and provided via stdin when required.
  - Unauthorized or malformed requests will be rejected.

EOF
}


[ -f "$CA_CERT" ] || { echo "CA cert not found"; exit 1; }
[ -f "$CA_KEY" ]  || { echo "CA key not found"; exit 1; }

MASTER_NAME="${SSH_ORIGINAL_COMMAND:-}"

case "$MASTER_NAME" in
  get-certificate)
    cat "$CA_CERT"
    exit 0
    ;;
  get-peers)
    /usr/local/bin/etcdctl --endpoints=https://$(hostname -I | awk '{print $1}'):2379 --cacert=/etc/etcd/pki/ca.crt --cert=/etc/etcd/pki/server.crt --key=/etc/etcd/pki/server.key member list | awk -F', ' '{print $5}'
    exit 0
    ;;
  get-topology)
    /usr/local/bin/etcdctl --endpoints=https://$(hostname -I | awk '{print $1}'):2379 --cacert=$CA_CERT --cert=/etc/etcd/pki/server.crt --key=/etc/etcd/pki/server.key member list | awk -F', *' '{ printf "%s%s=%s", (NR>1 ? "," : ""), $3, $4 }'
    exit 0
    ;;
  --help|"")
    usage
    exit 0
    ;;
esac

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

CSR="$TMPDIR/client.csr"
CERT="$TMPDIR/client.crt"
EXT="$TMPDIR/ext.cnf"

if ! timeout 3s sh -c 'cat | base64 -d | head -c 16384' > "$CSR"; then
  echo "CSR read timeout or invalid input"
  exit 3
fi

if [[ ! -s "$CSR" ]]; then
  echo "Empty CSR"
  exit 3
fi

if ! openssl req -in "$CSR" -noout >/dev/null 2>&1; then
  echo "Invalid CSR"
  exit 3
fi


if [[ "$MASTER_NAME" =~ ^etcd-[a-zA-Z0-9_-]+=(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])){3}$ ]]; then
  DAYS_VALID=3650
  NODE_NAME="${MASTER_NAME%%=*}"
  NODE_IP="${MASTER_NAME##*=}"
  cat > "$EXT" <<EOF
subjectAltName = DNS:$NODE_NAME,IP:$NODE_IP
extendedKeyUsage = serverAuth,clientAuth
keyUsage = digitalSignature,keyEncipherment
EOF
  echo 01 > "$TMPDIR/ca.srl"

  openssl x509 \
    -req \
    -in "$CSR" \
    -CA "$CA_CERT" \
    -CAkey "$CA_KEY" \
    -CAserial "$TMPDIR/ca.srl" \
    -out "$CERT" \
    -days "$DAYS_VALID" \
    -extfile "$EXT"

  cat "$CERT"
  /usr/local/bin/etcdctl --endpoints=https://$(hostname -I | awk '{print $1}'):2379 --cacert=$CA_CERT --cert=/etc/etcd/pki/server.crt --key=/etc/etcd/pki/server.key member add $NODE_NAME --peer-urls=https://$NODE_IP:2380   >&2

elif [[ "$MASTER_NAME" =~ ^kubemaster-[a-zA-Z0-9_-]+$ ]]; then
  cat > "$EXT" << EOF
basicConstraints = CA:FALSE 
keyUsage = digitalSignature 
extendedKeyUsage = clientAuth 
subjectAltName = DNS:${MASTER_NAME} 

EOF


  echo 01 > "$TMPDIR/ca.srl" 
  openssl x509 \
    -req \
    -in "$CSR" \
    -CA "$CA_CERT" \
    -CAkey "$CA_KEY" \
    -CAserial "$TMPDIR/ca.srl" \
    -out "$CERT" \
    -days "$DAYS_VALID" \
    -extfile "$EXT"
  cat "$CERT"

elif [[ "$MASTER_NAME" =~ ^sign-clientcert$ ]]; then
  openssl x509 \
    -req \
    -in "$ETCD_PKI_DIR/signer.csr" \
    -CA "$CA_CERT" \
    -CAkey "$CA_KEY" \
    -CAcreateserial \
    -out "/authority/etcdclient.crt" \
    -days "$DAYS_VALID" \
    -extfile "$ETCD_PKI_DIR/clientext.txt"
else
  echo "Invalid requester name ($MASTER_NAME)"
  exit 2
fi

logger "etcd-ca: issued client cert for ${MASTER_NAME}"
