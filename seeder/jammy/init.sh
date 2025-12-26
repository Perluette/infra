#!/bin/bash

TRUSTED_STORE=../
TRUSTED_BASE_IMAGE=jammy-server-cloudimg-amd64.img
BUILT_IMAGE_NAME=jammy-server-cloudimg-amd64-k8s.qcow2

rm -rf jammy-server-cloudimg-amd64*
cp $TRUSTED_STORE$TRUSTED_BASE_IMAGE ./$BUILT_IMAGE_NAME


qemu-img resize $BUILT_IMAGE_NAME 10G

virt-customize -a $BUILT_IMAGE_NAME \
  --run-command 'growpart /dev/sda 1' \
  --run-command 'resize2fs /dev/sda1' \
  --upload etc/sysctl.d/99-kubernetes-cri.conf:/etc/sysctl.d/99-kubernetes-cri.conf \
  --upload etc/ssh/sshd_config:/etc/ssh/sshd_config \
  --run-command "echo overlay >> /etc/modules-load.d/k8s.conf" \
  --run-command "echo br_netfilter >> /etc/modules-load.d/k8s.conf" \
  --install ca-certificates,curl,gnupg,qemu-guest-agent,containerd \
  --upload etc/modules-load.d/containerd.conf:/etc/modules-load.d/containerd.conf \
  --run-command "mkdir -p /etc/containerd" \
  --upload etc/containerd/config.toml:/etc/containerd/config.toml \
  --run-command "mkdir -p /etc/apt/keyrings" \
  --run-command "curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes.gpg" \
  --run-command "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' > /etc/apt/sources.list.d/kubernetes.list" \
  --install kubelet,kubeadm,kubectl \
  --run-command "apt-mark hold kubelet kubeadm kubectl" \
  --run-command "systemctl disable kubelet" \
  --write "/etc/licence.txt:K8s Golden Image" \
  --run-command 'systemctl enable qemu-guest-agent' \
  --run-command "cloud-init clean" \
  --run-command "truncate -s 0 /etc/machine-id"

chmod 444 $BUILT_IMAGE_NAME
sha256sum $BUILT_IMAGE_NAME > $BUILT_IMAGE_NAME.sha256

