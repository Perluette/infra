# Etcd golden image (1002)
This repository contains all resources required to build and prepare the etcd appliance image.

*See also*: [etcd v3.6.7 release page](https://github.com/etcd-io/etcd/releases/tag/v3.6.7)

## Purpose:
- Provide a reproducible process to create an etcd appliance image ready for deployment.
- Ensure full control over binaries, configuration, **and PKI**.
- Guarantee appliance immutability post first-boot.

## Structure:
- `build.sh` : Main script to assemble the appliance image. Responsibilities include:
  - Copying a trusted base image.
  - Resizing the disk as needed.
  - Uploading binaries (etcd, etcdctl) and configuration files.
  - Installing required packages such as ca-certificates and jq.
  - Uploading systemd service definitions.
  - Uploading first-boot resources into /root/setup.
  - Preparing the image for cloud-init usage.
- `etc/` : Contains configuration files, including:
  - `default/etcd` : Environment file used by the etcd systemd service.
  - `ssh/sshd_config` : SSH server configuration.
- `lib/systemd/system/` : Contains systemd unit files for etcd.
- `usr/local/bin/` : Contains the etcd and etcdctl binaries.
- `usr/local/share/etcd/pki/` : Embedded CA and appliance PKI templates.
- `setup/` : Contains first-boot scripts and templates for the appliance. This folder is copied into the image and executed once at first boot.
- `runbook.md` : Operational guide and step-by-step instructions for deploying the appliance.

## Build and First-Boot Workflow:
1. The `build.sh` script is executed to generate the appliance image.
2. The image is prepared with all required binaries, configs, and embedded PKI.
3. On first boot, the `first-boot.sh` script from `/root/setup` runs:
    - Stops the etcd service temporarily.
    - Detects if a configuration has been injected via cloud-init.
    - Generates a unique appliance certificate signed by the embedded CA if no injected configuration exists.
    - Applies the etcd configuration template with the appliance's dynamic IP and TLS settings.
    - Restarts etcd with the correct configuration.
    - Cleans up **all first-boot resources**, leaving the appliance immutable.
4. The appliance is ready to serve client requests securely after first boot.

## Audit and Security Notes:
- All binaries, configuration files, and PKI are fully controlled and included in the image at build time.
- The appliance is immutable post first-boot; the /root/setup folder is removed.
- Responsibility for initial configuration injection via cloud-init is on the operator. The appliance only auto-configures itself if no injected configuration is present.
- Logs of first-boot actions are temporarily stored in /root/setup/setup.log and removed along with the folder.
- No external dependencies or internet access are required during first-boot; everything is contained within the image.


---

echo command="/authority/request.sh",no-pty,no-port-forwarding,no-X11-forwarding $(cat ed25519.pub) 