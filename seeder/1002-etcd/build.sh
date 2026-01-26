#!/bin/bash

TRUSTED_STORE=../
TRUSTED_BASE_IMAGE=noble-server-cloudimg-amd64.img
BUILT_IMAGE_NAME=noble-server-cloudimg-amd64-etcd.qcow2

rm -rf noble-server-cloudimg-amd64-*
cp $TRUSTED_STORE$TRUSTED_BASE_IMAGE ./$BUILT_IMAGE_NAME
qemu-img resize $BUILT_IMAGE_NAME 10G

virt-customize -a $BUILT_IMAGE_NAME \
  --run-command 'growpart /dev/sda 1' \
  --run-command 'resize2fs /dev/sda1' \
  --upload runbook.md:/root/runbook.md \
  --run-command 'mkdir -p /root/setup /etc/etcd/pki /authority' \
  --upload setup/first-boot.sh:/root/setup/first-boot.sh \
  --upload authority/request.sh:/authority/request.sh \
  --run-command 'useradd --system --create-home --shell /bin/sh --comment "etcd certificate signer" signer && mkdir -p /home/signer/.ssh' \
  --upload home/signer/.ssh/authorized_keys:/home/signer/.ssh/authorized_keys \
  --run-command 'chmod 640 /authority/request.sh && chmod +x /authority/request.sh && chown root:signer /authority/request.sh && chattr +i /authority/request.sh' \
  --upload setup/etcd.conf:/root/setup/etcd.conf \
  --upload etc/etcd/pki/ca.crt:/etc/etcd/pki/ca.crt \
  --upload etc/etcd/pki/ca.key:/etc/etcd/pki/ca.key \
  --upload etc/etcd/pki/ca.srl:/etc/etcd/pki/ca.srl \
  --upload etc/etcd/pki/server.crt:/etc/etcd/pki/server.crt \
  --upload etc/etcd/pki/server.csr:/etc/etcd/pki/server.csr \
  --upload etc/etcd/pki/server.key:/etc/etcd/pki/server.key \
  --upload etc/ssh/sshd_config:/etc/ssh/sshd_config \
  --upload usr/local/bin/etcd:/usr/local/bin/etcd \
  --upload usr/local/bin/etcdctl:/usr/local/bin/etcdctl \
  --run-command 'chmod +x /usr/local/bin/etcd /usr/local/bin/etcdctl' \
  --install ca-certificates,jq,openssl,qemu-guest-agent \
  --run-command 'systemctl enable qemu-guest-agent' \
  --run-command 'chown root:signer /etc/etcd/pki/ca.key && chmod 640 /etc/etcd/pki/ca.key' \
  --upload etc/default/etcd:/etc/default/etcd \
  --upload lib/systemd/system/etcd.service:/lib/systemd/system/etcd.service \
  --run-command 'systemctl daemon-reload' \
  --run-command 'systemctl enable etcd' \
  --run-command 'rm -rf /var/lib/apt/lists/*' \
  --run-command "cloud-init clean" \
  --run-command "truncate -s 0 /etc/machine-id"

chmod 444 $BUILT_IMAGE_NAME
sha256sum $BUILT_IMAGE_NAME > $BUILT_IMAGE_NAME.sha256
