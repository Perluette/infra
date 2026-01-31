#!/bin/bash
set -euo pipefail

SETUP_DIR=/root/setup
ETCD_PKI_DIR=/etc/etcd/pki
ETCD_CONF_TEMPLATE="$SETUP_DIR/etcd.conf"
LOG_FILE=/root/setup.log

mkdir -p "$ETCD_PKI_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

echo "==== First-boot started at $(date) ====" >> "$LOG_FILE"

systemctl stop etcd >> "$LOG_FILE" 2>&1
echo "Stopped etcd service" >> "$LOG_FILE"

LISTEN_URL=$(grep -oP '(?<=^ETCD_LISTEN_CLIENT_URLS=).*' /etc/default/etcd || true)

if [[ "$LISTEN_URL" != '"http://127.0.0.1:2379"' ]]; then
    echo "Detected injected etcd config, skipping bootstrap" >> "$LOG_FILE"
    rm -rf "$SETUP_DIR"
    echo "Removed setup directory" >> "$LOG_FILE"
    exit 0
fi
echo "No injected conf detected, proceeding with bootstrap" >> "$LOG_FILE"

IP=$(ip -4 addr show dev eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
echo "Detected appliance IP: $IP" >> "$LOG_FILE"

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
openssl req -new -key "$ETCD_PKI_DIR/server.key" -out "$ETCD_PKI_DIR/server.csr" -subj "/CN=etcd-bootstrap" -addext "subjectAltName=DNS:$HOSTNAME,IP:$(ip -4 addr show dev eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')"
echo "Generating server.crt" >> "$LOG_FILE"
openssl x509 -req -in "$ETCD_PKI_DIR/server.csr" -CA "$ETCD_PKI_DIR/ca.crt" -CAkey "$ETCD_PKI_DIR/ca.key" -CAcreateserial -out "$ETCD_PKI_DIR/server.crt" -days 3650 -sha256 -copy_extensions copy
echo "Generated unique appliance certificate signed by CA" >> "$LOG_FILE"

sed "s/PLACEHOLDER_IP/$IP/g" "$ETCD_CONF_TEMPLATE" > /etc/default/etcd
echo "Copied etcd.conf template and replaced IP" >> "$LOG_FILE"

systemctl restart etcd >> "$LOG_FILE" 2>&1
echo "Restarted etcd service" >> "$LOG_FILE"

rm -rf "$SETUP_DIR"
echo "Removed setup directory" >> "$LOG_FILE"
echo "==== First-boot completed at $(date) ====" >> "$LOG_FILE"

echo "First-boot finished successfully. See $LOG_FILE for details."
