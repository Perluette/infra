```bash
kubectl label nodes <nodenames> node-role=argocd
kubectl taint nodes <nodenames> node-role=argocd:NoExecute
```
kubectl apply -f seeder/2001-argocd/crds/*.yaml
kubectl apply -n argocd -f seeder/2001-argocd/argocd.yaml