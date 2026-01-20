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


---



| Port         | Protocole | Usage                                    |
| ------------ | --------- | ---------------------------------------- |
| **TCP 6783** | TCP       | **Contrôle Weave Net (peer control)**    |
| **UDP 6783** | UDP       | **Données overlay (partie du datapath)** |
| **UDP 6784** | UDP       | **Données overlay (secondaire)**         |


| Port                | Protocole | Usage                                               |
| ------------------- | --------- | --------------------------------------------------- |
| **TCP 6443**        | TCP       | Kubernetes API (control-plane)                      |
| **TCP 10250**       | TCP       | Kubelet API – santé / démarrage des containers      |
| **TCP 30000-32767** | TCP/UDP   | NodePort Services (si tu en utilises)               |
| **TCP 2379-2380**   | TCP       | etcd (entre control-planes ou control-plane ↔ etcd) |


| Port                | Protocole | Usage                                                                                              |
| ------------------- | --------- | -------------------------------------------------------------------------------------------------- |
| **TCP 6781 / 6782** | TCP       | **Metrics / monitoring Weave Net** *(ouvrir uniquement si tu collectes des métriques entre hôtes)* |




# Weave Net (overlay)
TCP 6783 <-> ALL NODES
UDP 6783 <-> ALL NODES
UDP 6784 <-> ALL NODES

# Kubernetes infra
TCP 6443 <-> ALL NODES (API Server)
TCP 10250 <-> ALL NODES (kubelet)
TCP 30000-32767 <-> ALL NODES (NodePort, si utilisé)

# Control-Plane only
TCP 2379-2380 <-> etcd peers / control-plane


---


vmbr0	192.168.3.61	Home LAN
vmbr1	192.168.1.253	Public WAN
vmbr11	10.0.0.0/26	Front		[0-63]		1-50
vmbr12	10.0.0.64/26	Middle		[64-127]	65-114
vmbr13	10.0.0.128/26	Back		[128-191]	129-178
vmbr14	10.0.0.192/26	Vault		[192-255]	193-242