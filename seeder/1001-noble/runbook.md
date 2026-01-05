# Golden Kubernetes Image

modprobe overlay
modprobe br_netfilter
reboot

sudo kubeadm init --config kubeadm-config.yaml --upload-certs

kubectl apply -f weave.yaml


kubectl run console -it --image nicolaka/netshoot -- /bin/bash
