# K8s configuration

This k8s platform is built via `kubeadm` commands. All configurations are provided through yaml configuration files. More informations at [Kubeadm configuration official documentation](https://kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta3/)

## Templating
In order to standardize the deployment, the configuration files are templatized. The variables used to make the template replacement are conventianally prefixed with `TPL_`