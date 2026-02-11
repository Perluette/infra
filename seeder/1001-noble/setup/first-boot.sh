#!/bin/bash
set -euo pipefail

COMMAND=${1:-}
shift

TOKEN=""
CA_CERT_HASHE=""
IS_CONTROL_PLANE=false
CERTIFICATE_KEY=""
SETUP_DIR=/root/setup

parse_opts() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --token=*)
        TOKEN="${1#*=}"
        ;;
      --token)
        [[ $# -ge 2 ]] || { echo "--token requires a value"; exit 1; }
        TOKEN="$2"
        shift
        ;;
      --ca-cert-hash=*)
        CA_CERT_HASHE="${1#*=}"
        ;;
      --ca-cert-hash)
        [[ $# -ge 2 ]] || { echo "--ca-cert-hash requires a value"; exit 1; }
        CA_CERT_HASHE="$2"
        shift
        ;;
      --control-plane)
        IS_CONTROL_PLANE=true
        ;;
      --certificate-key=*)
        CERTIFICATE_KEY="${1#*=}"
        ;;
      --certificate-key)
        [[ $# -ge 2 ]] || { echo "--certificate-key requires a value"; exit 1; }
        CERTIFICATE_KEY="$2"
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

render_taints() {
  local taints=("$@")

  if [ "${#taints[@]}" -eq 0 ]; then
    echo "  taints: null"
    return
  fi

  echo "  taints:"
  for t in "${taints[@]}"; do
    IFS='|' read -ra fields <<< "$t"

    local first=1
    for f in "${fields[@]}"; do
      key="${f%%=*}"
      val="${f#*=}"

      if [ $first -eq 1 ]; then
        echo "  - $key: $val"
        first=0
      else
        echo "    $key: $val"
      fi
    done
  done
}


if [[ "$COMMAND" == "init" ]]; then
  echo "Entering Init cluster procedure..."
  /usr/local/bin/getEtcdClientCertificate
  ETCD_PEERS=$(ssh signer@$SIGNER_IP "get-peers" | sed "s/^/      - /")
  echo "External etcd peers detected."
  awk -v peers="$ETCD_PEERS" '
    /\$\{TPL_ETCD_ENDPOINTS\}/ {
      print peers
      next
    }
    { print }
  ' $SETUP_DIR/init-template.yaml $SETUP_DIR/cluster-template.yaml \
  | sed \
    -e "s@\${TPL_TOKEN}@$(tr -dc 'a-z0-9' </dev/urandom | head -c6).$(tr -dc 'a-z0-9' </dev/urandom | head -c16)@g" \
    -e "s@\${TPL_LOCALIP}@$(hostname -I | awk '{print $1}')@g" \
    -e "s@\${TPL_HOSTNAME}@$HOSTNAME@g" \
    -e "s@\${TPL_DNS}@$CONTROL_PLANE_DNS@g" | tee $SETUP_DIR/kubeadm-config.yaml > /dev/null

    kubeadm init --config $SETUP_DIR/kubeadm-config.yaml --upload-certs
elif [[ "$COMMAND" == "join" ]]; then
  echo "Entering join cluster procedure..."
  cat $SETUP_DIR/join-template.yaml | sed \
  -e 's@\${TPL_DNS}@'"$CONTROL_PLANE_DNS"'@g' \
  -e 's@\${TPL_HOSTNAME}@'"$HOSTNAME"'@g' \
  -e 's@\${TPL_TOKEN}@'"$TOKEN"'@g' \
  -e 's@\${TPL_CACERTHASHE}@'"$CA_CERT_HASHE"'@g' \
  | tee $SETUP_DIR/kubeadm-config.yaml > /dev/null
  if [[ "$IS_CONTROL_PLANE" == true ]]; then
    echo "Control-plane role requested, implanting certificateKey..."
    if [[ -z "$CERTIFICATE_KEY" ]]; then
      echo "ERROR: --control-plane requires --certificate-key"
      exit 1
    fi
    /usr/local/bin/getEtcdClientCertificate
    TAINTS=(
      "key=node-role.kubernetes.io/control-plane|effect=NoSchedule"
    )
    ETCD_PEERS=$(ssh signer@$SIGNER_IP "get-peers" | sed "s/^/      - /")
    cat <<EOF >> $SETUP_DIR/kubeadm-config.yaml

controlPlane:
  certificateKey: $CERTIFICATE_KEY
EOF
  fi
  
  TAINTS_YAML=$(render_taints "${TAINTS[@]}")
  gawk -i inplace -v taints="$TAINTS_YAML" '/\$\{TPL_TAINTS\}/ {print taints; next} {print}' $SETUP_DIR/kubeadm-config.yaml
  kubeadm join --config $SETUP_DIR/kubeadm-config.yaml
else
  echo "Unknown command."
  exit 1
fi

rm -rf $SETUP_DIR