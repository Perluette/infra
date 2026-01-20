```
wget https://raw.githubusercontent.com/argoproj/argo-cd/refs/tags/stable/manifests/crds/application-crd.yaml
wget https://raw.githubusercontent.com/argoproj/argo-cd/refs/tags/stable/manifests/crds/applicationset-crd.yaml
wget https://raw.githubusercontent.com/argoproj/argo-cd/refs/tags/stable/manifests/crds/appproject-crd.yaml
```
kubect apply *.yaml