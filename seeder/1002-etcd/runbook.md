# Runbook – Single-node etcd appliance → Cluster Setup

## 1. Initial Situation

- The image is built as a single-node etcd appliance.
- The /etc/default/etcd file contains a minimal configuration that allows etcd to start immediately.
- Data directory: /var/lib/etcd (on root disk).
- Systemd unit etcd.service is enabled at boot.
- SSH is configured according to uploaded sshd_config.
- Cloud-init has been cleaned; machine-id is empty.
- Disk has been resized via growpart + resize2fs.

## 2. Design Principles

- The appliance must always start in single-node mode if no cluster config is injected.
- Cluster formation requires explicit configuration and data-dir reset, because Raft consensus is sensitive to member changes.
- VIPs, load balancers, or dynamic discovery are not used or recommended for etcd.
- Cloud-init or manual provisioning can override the configuration at first boot only.

## 3. Preparing for Cluster Formation

- Ensure each new node has:

  - A unique name in /etc/default/etcd (ETCD_NAME)
  - Correct peer URLs (ETCD_INITIAL_ADVERTISE_PEER_URLS, ETCD_LISTEN_PEER_URLS)
  - Correct client URLs (ETCD_ADVERTISE_CLIENT_URLS, ETCD_LISTEN_CLIENT_URLS)
  - ETCD_INITIAL_CLUSTER listing all nodes that will participate
  - ETCD_INITIAL_CLUSTER_STATE set to "new"

## 4. Steps to Transition a Single-node Appliance to a Cluster Node

### 4.1. Stop etcd on the node:
```
systemctl stop etcd
```

### 4.2. Wipe existing data (mandatory to join a new cluster safely):
```
rm -rf /var/lib/etcd/*
```

### 4.3. Update configuration `/etc/default/etcd` with full cluster info:

  - `ETCD_NAME`: unique node name
  - `ETCD_INITIAL_CLUSTER`: all nodes in the cluster
  - `ETCD_INITIAL_CLUSTER_STATE`: "new"
  - Peer and client URLs updated for this node

### 4.4. Start etcd service:
```
systemctl start etcd
```

### 4.5. Verify node health:
```
etcdctl endpoint health
```

## 5. Notes and Recommendations

- ETCD_INITIAL_CLUSTER is immutable; changing it on a running cluster will corrupt Raft.
- Data-dir reset is mandatory when joining an existing cluster.
- Always use fixed hostnames or IPs for peers; do not rely on VIPs or dynamic load balancers.
- Single-node mode is intended for testing, dev, or appliance bootstrapping. Production HA requires explicit cluster configuration.

## 6. Optional Automation

- You can automate steps 3-4 via cloud-init for cluster deployment.
- For dev purposes, single-node is fully functional without cloud-init injection.
- Run a health check at first boot to ensure etcd is up:
```
systemctl is-active etcd && echo "etcd ready"
```
---
This runbook covers the full lifecycle from initial single-node appliance to joining a multi-node cluster, safely and reproducibly.