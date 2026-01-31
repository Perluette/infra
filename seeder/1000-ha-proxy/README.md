Observation: To achieve a fully functional HAProxy endpoint for the Kubernetes API Server that supports multi-master joins, several design choices and compromises were necessary. The configuration uses TCP passthrough only, without SSL termination on HAProxy, ensuring that kubeadm and other clients see the real certificates of the masters. Healthchecks are limited to simple TCP checks on port 6443, meaning HAProxy only verifies that the port is open and does not validate the API Server health beyond connectivity. Round-robin load balancing is used, which is stable but does not account for actual load or server performance. Logging is directed to stdout for audit purposes, and no internal inspection of HTTPS traffic is performed. These decisions prioritize compatibility, stability, and auditability over advanced health monitoring or TLS inspection.

# TL;DR
`nano /etc/keepalived/keepalived.conf`
```
global_defs {
    router_id <groupname>-<domain>-<index>
}

vrrp_instance VI_1 {
    state <MASTER|BACKUP>
    interface eth0
    virtual_router_id <routerid>
    priority <150|...decreasing>
    advert_int 0.5
    authentication {
        auth_type PASS
        auth_pass 42Secure
    }
    virtual_ipaddress {
        10.0.0.179/26
    }
}
```
systemctl daemon-reload
systemctl restart keepalived

`nano /etc/haproxy/haproxy.cfg`
## Back
```
global
    log /dev/log local0
    log /dev/log local1 notice
    daemon
    maxconn 2000
    tune.ssl.default-dh-param 2048

defaults
    log global
    mode tcp
    option tcplog
    option dontlognull
    timeout connect 2s
    timeout client 1m
    timeout server 1m

frontend kubernetes-apiserver
    bind 0.0.0.0:6443
    default_backend kubernetes-masters

backend kubernetes-masters
    mode tcp
    option tcp-check
    balance roundrobin
    server kubemaster-<id> <ip>:6443 check
```
## Front
```
global
    log /dev/log local0
    log /dev/log local1 notice
    daemon
    maxconn 2000
    tune.ssl.default-dh-param 2048

defaults
    log     global
    mode    tcp
    option  tcplog
    timeout connect 5s
    timeout client  30s
    timeout server  30s

frontend k8s_edge_http
    bind *:80
    mode tcp
    default_backend k8s_edge_backend_http

frontend k8s_edge_https
    bind *:443
    mode tcp
    default_backend k8s_edge_backend_https

backend k8s_edge_backend_http
    mode tcp
    balance roundrobin
    option tcp-check
    server kubemaster-edge-b09c6096 10.0.0.5:30080 check
    server kubemaster-edge-dbc8fedc 10.0.0.6:30080 check

backend k8s_edge_backend_https
    mode tcp
    balance roundrobin
    option tcp-check
    server kubemaster-edge-b09c6096 10.0.0.5:30443 check
    server kubemaster-edge-dbc8fedc 10.0.0.6:30443 check
```
systemctl restart haproxy
