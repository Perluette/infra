



kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v3.6/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml

kubectl apply -f traefik.yaml

test: kubectl apply -f whoami.yaml

kubectl label nodes <nodenames> node-role=edge
kubectl taint nodes <nodenames> node-role=edge:NoExecute