#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
PATH=/usr/sbin:/usr/bin:/sbin:/bin
umask 077

CA_CERT="/etc/etcd/pki/ca.crt"
CA_KEY="/etc/etcd/pki/ca.key"
DAYS_VALID=1

[ -f "$CA_CERT" ] || { echo "CA cert not found"; exit 1; }
[ -f "$CA_KEY" ]  || { echo "CA key not found"; exit 1; }

MASTER_NAME="${SSH_ORIGINAL_COMMAND:-}"
if [[ "$MASTER_NAME" == "get-certificate" ]]; then
    cat "$CA_CERT"
    exit 0
fi
if [[ "$MASTER_NAME" == "get-peers" ]]; then
    /usr/local/bin/etcdctl --endpoints=https://$(hostname -I | awk '{print $1}'):2379 --cacert=/etc/etcd/pki/ca.crt --cert=/etc/etcd/pki/server.crt --key=/etc/etcd/pki/server.key member list | awk -F', ' '{print $5}'
    exit 0
fi
if [[ ! "$MASTER_NAME" =~ ^kubemaster-[a-zA-Z0-9_-]+$ ]]; then
  echo "Invalid master name ($MASTER_NAME)"
  exit 2
fi

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

CSR="$TMPDIR/client.csr"
CERT="$TMPDIR/client.crt"
EXT="$TMPDIR/ext.cnf"

base64 -d > "$CSR"

cat > "$EXT" <<EOF
basicConstraints = CA:FALSE
keyUsage = digitalSignature
extendedKeyUsage = clientAuth
subjectAltName = DNS:${MASTER_NAME}
EOF

# ---- create temp serial ----
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

logger "etcd-ca: issued client cert for ${MASTER_NAME}"
