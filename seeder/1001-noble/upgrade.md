# Upgrade k8s nodes

## TL;DR
```
kubeadm token create --print-join-command
kubeadm init phase upload-certs --upload-certs
```
Stick all together to get that pattern:
```
kubeadm join <LB_OR_MASTER_IP>:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --control-plane \
  --certificate-key <certificate-key>
```

after each node incorporation, remove one older from haproxy-kubemaster configuration then drain it:
```
kubectl drain kubemaster-<id> --ignore-daemonsets
```
Once drained (and cordonned as a consequence) remove the node from the cluster:
```
kubectl delete node kubemaster-<id>
```
