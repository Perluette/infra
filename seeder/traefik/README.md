# Déploiement Traefik Vanilla Cluster Kubernetes

## 1. Contexte et objectifs
- Cluster Kubernetes **vanilla** (>=1.32.5) déployé via kubeadm
- **CNI** : Weave
- Nodepool dédié pour flux entrants (edge nodes) avec HAProxy en front : NAT des ports 80/443 vers NodePort 30080/30443
- Objectif : déployer **Traefik** pour gérer ingress HTTP/HTTPS
- Test applicatif : déployer **whoami** pour valider le routage HTTP et HTTPS (TLS auto-signé)

## 2. Prérequis
1. Cluster Kubernetes opérationnel (>=1.32.5)
2. CNI Weave configuré et fonctionnel
3. Nodes edge étiquetés et taintés :
```bash
kubectl label nodes <nodenames> node-role=edge
kubectl taint nodes <nodenames> node-role=edge:NoExecute
```
4. HAProxy en front, NAT des ports vers NodePort :
    - HTTP 80 → NodePort 30080
    - HTTPS 443 → NodePort 30443
5. Accès kubectl configuré sur le cluster
6. DNS publique configurée pour FQDN utilisé (ex : whoami.example.com) pointant sur la VIP HAProxy

## 3. Déploiement des CRDs Traefik
Télécharger et appliquer la définition CRD air-gapped :
```
kubectl apply -f gateway-api-crd-definition-v1.4.1.yaml
```
*Note*: CRD : `traefik.io/v1alpha1` pour IngressRoute et autres ressources dynamiques Traefik

## 4. Déploiement Traefik
Appliquer le fichier `traefik.yaml` :
```bash
kubectl apply -f traefik.yaml
```
### Points clés de la configuration Traefik

- Namespace dédié : `ingress-system`
- ServiceAccount : `traefik`
- RBAC minimal mais complet pour CRD + Ingress
- EntryPoints :
  - web : port 80
  - websecure : port 443 + TLS auto-signé
- NodePort exposé : 30080 (HTTP), 30443 (HTTPS)
- Scheduling :
  - Affinité sur nodes edge
  - Toleration `NoExecute`
  - PodAntiAffinity pour HA

### Vérification des pods Traefik

```bash
kubectl get pods -n ingress-system
kubectl logs <traefik-pod> -n ingress-system
```

## 5. Déploiement Whoami pour test
Appliquer le fichier `whoami.yaml` :
```bash
kubectl apply -f whoami.yaml
```
### Vérification des pods
```bash
kubectl get pods -n default -l app=whoami
kubectl get svc -n default whoami
```

### Vérification IngressRoute
```bash
kubectl get ingressroute -n default whoami -o yaml
```

### Points clés de Whoami IngressRoute
- Entrypoints : `web`, `websecure`
- Route HTTP(S) vers Service `whoami` port 80
- Pas de secret TLS → Traefik utilise certificat auto-signé “default”

## 6. Tests
### HTTP
```bash
curl http://whoami.example.com
```
### HTTPS (auto-signé)
```bash
curl -k https://whoami.example.com
```
*Note*: Dans un navigateur : warning certificat auto-signé attendu

### Validation fonctionnelle
- HTTP et HTTPS répondent correctement
- Entrypoints et routage Traefik validés
- HAProxy → NodePort → Traefik → Service OK

## 7. HAProxy TCP NAT Configuration
```
global
    daemon
    maxconn 1024

defaults
    mode    tcp
    timeout connect 5s
    timeout client  30s
    timeout server  30s

frontend k8s_public_http
    bind *:80
    default_backend node_port_http

frontend k8s_public_https
    bind *:443
    default_backend node_port_https

backend node_port_http
    balance roundrobin
    option tcp-check
    server traefik-2e312279 10.0.0.2:30080 check

backend node_port_https
    balance roundrobin
    option tcp-check
    server traefik-2e312279 10.0.0.2:30443 check
```

## 8. Points importants / recommandations
1. **ContainerPort 443** : bien déclaré dans le Deployment Traefik
2. **Taint NoExecute** : volontaire pour isoler nodes edge, à assumer
3. **IngressClass** : temporaire si passage futur Gateway API
4. **Probes** : liveness/readiness non configurées pour cette phase, mais à prévoir pour production
5. **TLS auto-signé** : suffisant pour test et validation avant Cert-Manager
6. **DNS FQDN** : vérifier résolution correcte sur VIP HAProxy

## 9. Nettoyage (optionnel)
Pour supprimer Whoami après tests :
```bash
kubectl delete -f whoami.yaml
```
Pour supprimer Traefik (et CRDs si besoin) :
```bash
kubectl delete -f traefik.yaml
kubectl delete -f kubernetes-crd-definition-v1.yml
```

-------------------------------------
new release
kubectl apply -f seeder/traefik/gateway-api-crd-definition-v1.4.1.yaml (kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.1/standard-install.yaml)

kubectl apply -f seeder/traefik/gatewayclass-traefik.yaml

```
openssl genrsa -out traefik-generic.key 2048
openssl req -x509 -new -nodes -key traefik-generic.key -out traefik-generic.crt -days 3650 -subj "/CN=traefik.local/O=internal"
kubectl create secret tls traefik-generic --cert=traefik-generic.crt --key=traefik-generic.key -n ingress-system
```