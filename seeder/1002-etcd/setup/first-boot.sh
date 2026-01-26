#!/bin/bash
set -euo pipefail

SETUP_DIR=/root/setup
ETCD_PKI_DIR=/etc/etcd/pki
ETCD_CONF_TEMPLATE="$SETUP_DIR/etcd.conf"
LOG_FILE=/root/setup.log

mkdir -p "$ETCD_PKI_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

echo "==== First-boot started at $(date) ====" >> "$LOG_FILE"

# Stop etcd si déjà lancé
systemctl stop etcd >> "$LOG_FILE" 2>&1
echo "Stopped etcd service" >> "$LOG_FILE"

# --- 1. Détecter conf injectée ---
LISTEN_URL=$(grep -oP '(?<=^ETCD_LISTEN_CLIENT_URLS=).*' /etc/default/etcd || true)

if [[ "$LISTEN_URL" != '"http://127.0.0.1:2379"' ]]; then
    echo "Detected injected etcd config, skipping bootstrap" >> "$LOG_FILE"
    rm -rf "$SETUP_DIR"
    echo "Removed setup directory" >> "$LOG_FILE"
    exit 0
fi
echo "No injected conf detected, proceeding with bootstrap" >> "$LOG_FILE"

# --- 2. Récupérer IP dynamique ---
IP=$(ip -4 addr show dev eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
echo "Detected appliance IP: $IP" >> "$LOG_FILE"

# --- 3. Copier PKI embarqué ---
# cp /usr/local/share/etcd/pki/ca.crt "$ETCD_PKI_DIR/"
# cp /usr/local/share/etcd/pki/ca.key "$ETCD_PKI_DIR/"
# echo "Copied CA cert/key to PKI dir" >> "$LOG_FILE"

# --- 4. Générer certificat serveur unique ---
openssl genrsa -out "$ETCD_PKI_DIR/server.key" 2048 >> "$LOG_FILE" 2>&1
openssl req -new -key "$ETCD_PKI_DIR/server.key" -out "$ETCD_PKI_DIR/server.csr" -subj "/CN=$IP" >> "$LOG_FILE" 2>&1
openssl x509 -req -in "$ETCD_PKI_DIR/server.csr" -CA "$ETCD_PKI_DIR/ca.crt" -CAkey "$ETCD_PKI_DIR/ca.key" -CAcreateserial -out "$ETCD_PKI_DIR/server.crt" -days 365 -sha256 >> "$LOG_FILE" 2>&1
echo "Generated unique appliance certificate signed by CA" >> "$LOG_FILE"

# --- 5. Copier template et remplacer IP ---
sed "s/PLACEHOLDER_IP/$IP/g" "$ETCD_CONF_TEMPLATE" > /etc/default/etcd
echo "Copied etcd.conf template and replaced IP" >> "$LOG_FILE"

# --- 6. Démarrer etcd ---
systemctl restart etcd >> "$LOG_FILE" 2>&1
echo "Restarted etcd service" >> "$LOG_FILE"

# --- 7. Cleanup setup ---
rm -rf "$SETUP_DIR"
echo "Removed setup directory" >> "$LOG_FILE"
echo "==== First-boot completed at $(date) ====" >> "$LOG_FILE"

echo "First-boot finished successfully. See $LOG_FILE for details."
