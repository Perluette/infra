# Proxmox VM Template: HAProxy

## Overview
This document describes the Proxmox VM template prepared for deploying HAProxy instances in a hardened, high-quality, and CI/CD-ready supply chain environment.  
The template is designed for administrators to rapidly instantiate load balancers with secure defaults and consistent configuration.

---

## General Information

| Property                  | Value / Description |
|---------------------------|-------------------|
| Template Name             | `haproxy-template-v1` |
| OS                        | Debian 12 / Ubuntu 24.04 LTS (minimal install) |
| CPU                       | 2 vCPUs (adjustable per deployment) |
| Memory                    | 2048 MB RAM (adjustable per deployment) |
| Disk                      | 20 GB (thin-provisioned, QCOW2 format) |
| Network                   | 1 NIC, bridged to `vmbr0`, static IP configurable |
| Cloud-Init Support        | Yes (for automated provisioning) |
| Backup Strategy           | Compatible with Proxmox backup (LVM/ZFS) |
| Template Version          | 1.0 |
| Maintainer                | `platform-team@example.com` |

---

## Security Hardening

The VM template is hardened following organizational security standards:

- **OS Hardening**
  - Minimal base install (no unnecessary packages)
  - SSH key-based authentication only
  - Firewall enabled (ufw or iptables) with default deny
  - Automatic security updates enabled
- **HAProxy Hardening**
  - Default configuration includes SSL termination template
  - Cipher suite restricted to secure TLS versions
  - Logging enabled and directed to syslog
- **User and Access Control**
  - Non-root default user: `haproxyadmin`
  - Sudo privileges for administrative tasks only
  - Root login disabled over SSH
- **Monitoring**
  - Basic Prometheus/Node Exporter endpoint installed
  - Syslog forwarding configured for central logging

---

## Template Configuration Details

- **Proxmox VM ID**: Template ID only, to be cloned per deployment
- **Cloud-Init**
  - Supports network, hostname, SSH keys, and initial HAProxy configuration
- **Storage**
  - OS Disk: `/var/lib/vz/images/<vmid>/vm-<vmid>-disk-1.qcow2`
  - Persistent HAProxy configuration under `/etc/haproxy/`
- **Network**
  - Default interface: `ens18` bridged to `vmbr0`
  - DHCP optional, static IP recommended for production

---

## Pipeline & Supply-Chain Integration

This template is integrated in the CI/CD and supply-chain process:

1. **Template Build**
   - Automated using Packer or Proxmox API
   - Verified via Ansible or similar configuration management
   - Security baseline validated against CIS benchmarks
2. **Template Signing**
   - SHA256 checksum generation
   - Stored in internal artifact repository
3. **Deployment**
   - Cloned via Proxmox or API
   - Cloud-init applied automatically
   - Post-deployment verification using automated tests
4. **Updates**
   - Maintained via pipeline with repeatable builds
   - Security patches applied in CI/CD before deployment

---

## Usage Notes

- Recommended for HAProxy instances in production or staging environments.
- Always deploy clones rather than modifying the template directly.
- Integrate with existing monitoring and logging infrastructure.
- Follow organizational policies for secrets, SSL certificates, and sensitive configuration.

---

## References

- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [HAProxy Documentation](https://www.haproxy.org/documentation/)
- [CIS Benchmarks: Debian/Ubuntu](https://www.cisecurity.org/cis-benchmarks/)

---

**End of Document**
