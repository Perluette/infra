# Proxmox VM Template: Kubernetes Node (v1.32.5)

## Overview
This document describes the Proxmox VM template prepared for deploying Kubernetes v1.32.5 nodes on Ubuntu 24.04 LTS (“Noble”) in a hardened, CI/CD-ready, high-quality supply chain.  
The template is intended for administrators to instantiate production-ready or staging Kubernetes nodes with consistent configuration and security hardening.

---

## General Information

| Property                  | Value / Description |
|----------------------------|-------------------|
| Template Name              | `k8s-node-template-v1.32.5` |
| OS                         | Ubuntu 24.04 LTS Minimal Install |
| Kubernetes Version         | 1.32.5 |
| CPU                        | 4 vCPUs (adjustable per deployment) |
| Memory                     | 8192 MB RAM (adjustable per deployment) |
| Disk                       | 40 GB (thin-provisioned, QCOW2 format) |
| Network                    | 1 NIC bridged to `vmbr0`, static IP recommended |
| Cloud-Init Support         | Yes (hostname, network, SSH keys, initial kubeadm config) |
| Container Runtime          | containerd (hardened) |
| Backup Strategy            | Compatible with Proxmox backup (LVM/ZFS) |
| Template Version           | 1.0 |
| Maintainer                 | `platform-team@example.com` |

---

## Security Hardening

The VM template is hardened following organizational and Kubernetes security standards:

- **OS Hardening**
  - Minimal Ubuntu installation with only essential packages
  - SSH key-based authentication only
  - Firewall enabled (`ufw` default deny)
  - Unattended security updates enabled
  - Swap disabled (recommended for Kubernetes)
- **Kubernetes Hardening**
  - Kubernetes components preinstalled: `kubeadm`, `kubelet`, `kubectl`
  - Secure API access: RBAC enforced, TLS enabled
  - System services hardened (kubelet with read-only filesystem where applicable)
- **User and Access Control**
  - Non-root administrative user: `k8sadmin`
  - Sudo privileges restricted
  - Root login disabled over SSH
- **Networking**
  - Host networking tuned for Kubernetes (bridge CNI)
  - Firewall rules aligned with cluster requirements
- **Monitoring & Logging**
  - Node Exporter installed for Prometheus
  - Logs forwarded to central syslog/log aggregator

---

## Template Configuration Details

- **Proxmox VM ID**: Template ID only; clone per deployment
- **Cloud-Init**
  - Network configuration, hostname, SSH keys, initial kubeadm join configuration
- **Storage**
  - OS Disk: `/var/lib/vz/images/<vmid>/vm-<vmid>-disk-1.qcow2`
  - Persistent Kubernetes configuration: `/etc/kubernetes/`
  - Container runtime storage: `/var/lib/containerd/`
- **Network**
  - Default interface: `ens18` bridged to `vmbr0`
  - Static IP recommended for kubeadm and cluster communication

---

## Pipeline & Supply-Chain Integration

This template is fully integrated into the CI/CD pipeline and hardened supply chain:

1. **Template Build**
   - Automated via Packer or Proxmox API
   - Validated using Ansible or similar configuration management
   - Security baseline verified against CIS Kubernetes benchmarks
2. **Template Signing**
   - SHA256 checksum generated and stored in internal artifact repository
3. **Deployment**
   - Cloned via Proxmox or API
   - Cloud-init applied automatically
   - Post-deployment automated validation including kubelet status
4. **Updates**
   - Security patches applied in CI/CD before deployment
   - Kubernetes upgrades tested in pipeline prior to template update
   - Repeatable builds ensure reproducibility

---

## Usage Notes

- Recommended for Kubernetes cluster nodes in production or staging.
- Always deploy clones rather than modifying the template directly.
- Ensure kubeadm or cluster bootstrap scripts are applied after deployment.
- Integrate with existing monitoring, logging, and security policies.
- Maintain container runtime and OS patches according to organizational standards.

---

## References

- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Ubuntu 24.04 LTS Documentation](https://ubuntu.com/docs)
- [CIS Benchmarks: Kubernetes](https://www.cisecurity.org/cis-benchmarks/)

---

**End of Document**
