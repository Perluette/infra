# Golden Kubernetes Image

## Turn key procedure
### Setting environment variables (Should be done through cloud-init, ignored at runtime)
echo SIGNER_IP=10.0.0.193 >> /etc/environment
echo CONTROL_PLANE_DNS=k8s.caminade.fr >> /etc/environment

modprobe overlay
modprobe br_netfilter
reboot

## Etcd certificate request
This procedure is mandatory to init the cluster (Signs a node certificate from the etcd service). It also runs automatically at runtime to renew the node certificate.
Packaged as `getEtcdClientCertificate`

### Cluster Init


kubectl apply -f setup/weave.yaml
kubectl rollout restart -n kube-system daemonset weave-net && kubectl rollout restart -n kube-system daemonset kube-proxy && kubectl rollout restart -n kube-system deployment coredns

### just in case...
kubectl run console -it --image nicolaka/netshoot -- /bin/bash


## Load balancers
### api-server
WIP: This procedure generates the full haproxy configuration file for load-balance the api-server requests. It is intended to run automatically to maintain the load-balancer configuration up-to-date during the cluster lifecycle.
Packaged as `getHaproxyconf_apiserver`

### Edge
WIP: This procedure generates the full haproxy configuration file for load-balance the edge HTTP/HTTPS requests. It is intended to run automatically to maintain the load-balancer configuration up-to-date during the cluster lifecycle.
Packaged as `getHaproxyconf_edge`
*Note*: This procedure requires to fullfil the Traefik + Gateway-api deployment procedure first (one-shot).

## Joining new nodes
Kubeadm canonical form command to join a node could be expressed by the following command: `kubeadm join <api_endpoint>:6443 --token <token_value> --discovery-token-ca-cert-hash sha256:<ca_cert_hash_value> [--control-plane --certificate-key <certificate_key_value>]`

The `control-plane` and `certificate-key` switches are required only for joining a control-plane node.

This procedure is automated in this appliance in the `first-boot.sh` script. It requires at most 3 variables:

### token
A short-lived bootstrap token used by a new node to authenticate to the Kubernetes control plane when joining the cluster.

Obtained by issuing `kubeadm token create` on an active control-plane.

### discovery-token-ca-cert-hash
A hash of the cluster CA certificate used to verify the identity of the control plane and prevent man-in-the-middle attacks.

To obtain this value, issue the following command on an active control-plane: `openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'`

*note*: This is a SHA256 representation. Most of the time, it has to be prefixed by `sha256:`

### certificate-key
A shared key used to securely encrypt and transfer control plane certificates when adding a new control plane node.

This value can be obtained by issuing the following command on an active control-plane: `kubeadm init phase upload-certs --upload-certs 2>/dev/null | tail -n1`

*Note*: invoking this command de facto revoke the existing keys.