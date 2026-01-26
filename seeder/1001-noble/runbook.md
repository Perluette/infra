# Golden Kubernetes Image

modprobe overlay
modprobe br_netfilter
reboot

sudo kubeadm init --config kubeadm-config.yaml --upload-certs

kubectl apply -f weave.yaml


kubectl run console -it --image nicolaka/netshoot -- /bin/bash

kubectl rollout restart -n kube-system daemonset weave-net && kubectl rollout restart -n kube-system daemonset kube-proxy && kubectl rollout restart -n kube-system deployment coredns

## Etcd certificate request

ssh signer@10.0.0.193 -i .ssh/ed25519   "get-certificate" > /etc/kubernetes/pki/etcd/ca.crt
openssl req -new -newkey rsa:2048 -nodes   -keyout /etc/kubernetes/pki/etcd/client.key -out /etc/kubernetes/pki/etcd/client.csr -subj "/CN=ignored"
base64 < /etc/kubernetes/pki/etcd/etcd-client.csr | ssh signer@10.0.0.193 "$HOSTNAME" > /etc/kubernetes/pki/etcd/client.crt

