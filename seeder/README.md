# Seeder directory overview

This directory contains the components and scripts used to build and prepare the virtual machine images that serve as the foundation for the platform.
All images produced here are golden images, immutable by design, and rely on first-boot configuration to finalize instance-specific details.

The repository explicitly implements this model: images are built, versioned, and promoted; no configuration drift is expected; per-node initialization is handled at first boot.

## Image types

The seeder produces three types of images:

### 1. HAProxy image (Debian)
- Provides load balancing for Kubernetes API servers and edge NodePort services.
- Serves as a front for internal and external traffic.
- Configuration baked in the image; runtime adjustments are minimal and handled through first-boot scripts when necessary.

### 2. etcd image (Ubuntu)
- Provides a dedicated etcd node for control-plane operations.
- Ensures rolling upgrades and consistent cluster state management.
- TLS certificates and other trust artifacts are baked into the image.

### 3. Kubernetes node image (Ubuntu)
- Base image for control-plane and worker nodes.
- Versioned to align with the current Kubernetes release.
- Includes OS-level, container runtime, and Kubernetes prerequisites.

## Deploying images

A single script, deploy.sh, converts the qcow2 images generated in this directory into Proxmox VM templates.
- Must be executed as root on the Proxmox host.
- Produces templates ready to instantiate nodes according to their role (HAProxy, etcd, Kubernetes).
- No further transformation or manual configuration is required on the templates themselves.

## Operational notes
- All images are built, versioned, and promoted manually.
- Operator is responsible for lifecycle management, upgrades, and any first-boot configuration.
- This directory is not a general-purpose image factory.
- It is not intended to run outside of the platform described in the root README.

## Design philosophy
The seeder follows three guiding principles:
### 1. Golden images
- All system components are encapsulated in versioned, reproducible images.
- Every image represents a known good state of the system.

### 2. Immutable infrastructure
- Nodes are replaced, not modified in place.
- Configuration drift is considered an operational issue.

### 3. First-boot configuration
- Instance-specific parameters (network addresses, cluster membership, node roles) are applied at first boot.
- No node requires manual intervention post-deployment.

This model ensures clarity, repeatability, and predictable operations, fully aligned with the platform’s enterprise-grade, solo-operated goals.

## Limits and responsibilities
- Seeder does not manage cluster configuration directly.
- It does not include post-deployment configuration management beyond first-boot scripts.
- Operator must understand the implications of immutable images and handle updates, upgrades, and promotions responsibly.
- All outputs assume execution on the intended Proxmox environment.


---



| Port         | Protocole | Usage                                    |
| ------------ | --------- | ---------------------------------------- |
| **TCP 6783** | TCP       | **Contrôle Weave Net (peer control)**    |
| **UDP 6783** | UDP       | **Données overlay (partie du datapath)** |
| **UDP 6784** | UDP       | **Données overlay (secondaire)**         |


| Port                | Protocole | Usage                                               |
| ------------------- | --------- | --------------------------------------------------- |
| **TCP 6443**        | TCP       | Kubernetes API (control-plane)                      |
| **TCP 10250**       | TCP       | Kubelet API – santé / démarrage des containers      |
| **TCP 30000-32767** | TCP/UDP   | NodePort Services (si tu en utilises)               |
| **TCP 2379-2380**   | TCP       | etcd (entre control-planes ou control-plane ↔ etcd) |


| Port                | Protocole | Usage                                                                                              |
| ------------------- | --------- | -------------------------------------------------------------------------------------------------- |
| **TCP 6781 / 6782** | TCP       | **Metrics / monitoring Weave Net** *(ouvrir uniquement si tu collectes des métriques entre hôtes)* |




# Weave Net (overlay)
TCP 6783 <-> ALL NODES
UDP 6783 <-> ALL NODES
UDP 6784 <-> ALL NODES

# Kubernetes infra
TCP 6443 <-> ALL NODES (API Server)
TCP 10250 <-> ALL NODES (kubelet)
TCP 30000-32767 <-> ALL NODES (NodePort, si utilisé)

# Control-Plane only
TCP 2379-2380 <-> etcd peers / control-plane


---


vmbr0	192.168.3.61	Home LAN
vmbr1	192.168.1.253	Public WAN
vmbr11	10.0.0.0/26	Front		[0-63]		1-50
vmbr12	10.0.0.64/26	Middle		[64-127]	65-114
vmbr13	10.0.0.128/26	Back		[128-191]	129-178
vmbr14	10.0.0.192/26	Vault		[192-255]	193-242