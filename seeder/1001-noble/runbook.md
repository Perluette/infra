# Golden Kubernetes Image

sudo kubeadm init --config kubeadm-config.yaml

kubectl apply -f weave.yaml


kubectl run console -it --image nicolaka/netshoot -- /bin/bash
