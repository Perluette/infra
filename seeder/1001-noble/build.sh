#!/bin/bash

TRUSTED_STORE=../
TRUSTED_BASE_IMAGE=noble-server-cloudimg-amd64.img
BUILT_IMAGE_NAME=noble-server-cloudimg-amd64-k8s.qcow2

rm -rf noble-server-cloudimg-amd64*
cp $TRUSTED_STORE$TRUSTED_BASE_IMAGE ./$BUILT_IMAGE_NAME

qemu-img resize $BUILT_IMAGE_NAME 10G

virt-customize -a $BUILT_IMAGE_NAME \
  --run-command 'growpart /dev/sda 1' \
  --run-command 'resize2fs /dev/sda1' \
  --upload etc/ssh/sshd_config:/etc/ssh/sshd_config \
  --upload .ssh/id_ed25519:/root/.ssh/id_ed25519 \
  --upload .ssh/config:/root/.ssh/config \
  --run-command 'chmod 600 /root/.ssh/id_ed25519' \
  --install podman,apt-transport-https,ca-certificates,qemu-guest-agent \
  --upload etc/containers/registries.conf:/etc/containers/registries.conf \
  --run-command 'systemctl enable qemu-guest-agent' \
  --run-command "apt-get remove -y apparmor" \
  --run-command "mkdir -p /etc/apt/keyrings /etc/kubernetes/pki/etcd /root/setup" \
  --run-command "curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-1-35-apt-keyring.gpg" \
  --upload etc/apt/sources.list.d/kubernetes.list:/etc/apt/sources.list.d/kubernetes.list \
  --install containerd,kubelet=1.35.0-1.1,kubeadm=1.35.0-1.1,kubectl=1.35.0-1.1,kubernetes-cni \
  --run-command "apt-mark hold kubelet kubeadm kubectl" \
  --run-command "mkdir -p /etc/containerd" \
  --upload etc/modules-load.d/containerd.conf:/etc/modules-load.d/containerd.conf \
  --upload etc/sysctl.d/99-kubernetes-cri.conf:/etc/sysctl.d/99-kubernetes-cri.conf \
  --upload etc/modules-load.d/containerd.conf:/etc/modules-load.d/containerd.conf \
  --upload etc/sysctl.d/99-kubernetes-cri.conf:/etc/sysctl.d/99-kubernetes-cri.conf \
  --upload etc/containerd/config.toml:/etc/containerd/config.toml \
  --upload etc/crictl.yaml:/etc/crictl.yaml \
  --upload setup/weave.yaml:/root/setup/weave.yaml \
  --upload setup/init-template.yaml:/root/setup/init-template.yaml \
  --upload setup/join-template.yaml:/root/setup/join-template.yaml \
  --upload setup/cluster-template.yaml:/root/setup/cluster-template.yaml \
  --upload setup/first-boot.sh:/root/setup/first-boot.sh \
  --upload usr/local/bin/getHaproxyconf_apiserver:/usr/local/bin/getHaproxyconf_apiserver \
  --upload usr/local/bin/getHaproxyconf_edge:/usr/local/bin/getHaproxyconf_edge \
  --upload usr/local/bin/getEtcdClientCertificate:/usr/local/bin/getEtcdClientCertificate \
  --upload etc/cron.d/rotate-etcd-cert:/etc/cron.d/rotate-etcd-cert \
  --upload runbook.md:/root/runbook.md \
  --run-command "update-alternatives --set iptables /usr/sbin/iptables-legacy" \
  --run-command "update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy" \
  --run-command "systemctl disable nftables" \
  --run-command "systemctl mask nftables" \
  --run-command "cloud-init clean" \
  --run-command "truncate -s 0 /etc/machine-id"

chmod 444 $BUILT_IMAGE_NAME
sha256sum $BUILT_IMAGE_NAME > $BUILT_IMAGE_NAME.sha256
