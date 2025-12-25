# Seeder

This step intends to create the base platform image. It consists in an Ubuntu cloud-init ready with Kubernetes pre-built.

```
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
mv jammy-server-cloudimg-amd64.img jammy-server-cloudimg-amd64.qcow2

export LIBGUESTFS_BACKEND=direct LIBGUESTFS_DEBUG=1 LIBGUESTFS_TRACE=1
qemu-img resize jammy-server-cloudimg-amd64.qcow2 10G
                        qemu-img create -f qcow2 jammy-server-cloudimg-amd64-k8s-1.29.qcow2 10G
                        sudo virt-resize -v -x --expand /dev/sda3 jammy-server-cloudimg-amd64.qcow2 jammy-server-cloudimg-amd64-k8s-1.29.qcow2
                        rm -rf jammy-server-cloudimg-amd64.qcow2
sudo virt-customize \
  -a jammy-server-cloudimg-amd64-k8s-1.29.qcow2 \
  --install ca-certificates,curl,gnupg,qemu-guest-agent \
  --run-command "mkdir -p /etc/apt/keyrings" \
  --run-command "curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes.gpg" \
  --run-command "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' > /etc/apt/sources.list.d/kubernetes.list" \
  --install kubelet,kubeadm,kubectl \
  --run-command "apt-mark hold kubelet kubeadm kubectl" \
  --run-command "systemctl disable kubelet" \
  --write "/etc/licence.txt:Déployé par Toto" \
  --hostname jammy-seed \
  --run-command "cloud-init clean" \
  --run-command "truncate -s 0 /etc/machine-id"
chmod 444 jammy-server-cloudimg-amd64-k8s-1.29.qcow2
sha256sum jammy-server-cloudimg-amd64-k8s-1.29.qcow2 > jammy-server-cloudimg-amd64-k8s-1.29.qcow2.sha256
```

# Proxmox deployment
## Image copy
```
scp jammy-server-cloudimg-amd64-k8s-1.29.qcow2 root@proxmox:/root/
```

## VM Template
```
qm create 9000 \
  --name jammy-k8s-test \
  --memory 2048 \
  --cores 2 \
  --net0 virtio,bridge=vmbr0 \
  --ostype l26

qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0

qm set 9000 --boot order=scsi0

qm set 9000 --ide2 local-lvm:cloudinit

qm set 9000 --serial0 socket --vga serial0

```
