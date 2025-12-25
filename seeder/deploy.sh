#!/bin/bash

BASENAME=noble
IMG_NAME=$BASENAME-server-cloudimg-amd64.qcow2
VMNAME=golden-$BASENAME-k8s
VM_MEM=2048
VM_CORES=2
VM_NET=virtio,bridge=vmbr0
VM_ID=9000

echo Creating VM
qm create $VM_ID --name $VMNAME --memory $VM_MEM --cores $VM_CORES --net0 $VM_NET --ostype l26 --agent 1
echo Importing disk
qm importdisk $VM_ID /root/$BASENAME/$IMG_NAME local-lvm
echo Setting HW options
qm set $VM_ID --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-$VM_ID-disk-0
echo Setting boot order
qm set $VM_ID --boot order=scsi0
echo Setting cloud-init drive
qm set $VM_ID --ide2 local-lvm:cloudinit
