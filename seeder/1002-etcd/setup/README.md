# Setup folder
This folder contains the resources and scripts required for the first-boot initialization of the etcd appliance.

## Purpose:
- Enable the appliance to bootstrap itself when started for the first time.
- Generate a unique appliance certificate signed by the embedded CA.
- Detect if a configuration has been injected via cloud-init and skip bootstrap if so.
- Configure the etcd service to listen on the appliance's dynamic IP with TLS.
- Ensure immutability post first-boot by removing all setup resources.

## Structure:
- first-boot.sh : The main initialization script executed at first boot. Responsibilities include:
  - Stop the etcd service temporarily.
  - Detect whether an injected configuration exists.
  - Determine the appliance's IP address dynamically.
  - Copy the embedded CA certificate and key to the appliance PKI directory.
  - Generate a unique certificate for this appliance signed by the CA.
  - Apply the etcd configuration template (etcd.conf) with the correct IP and TLS paths.
  - Restart the etcd service with the new configuration.
  - Self-destruct by deleting the setup folder, leaving the appliance clean.
  - Log all actions to /root/setup.log for debugging purposes.
- README.md : This document, explaining the purpose and usage of the setup folder.
- etcd.conf (template) : Placeholder configuration template for etcd. The script replaces placeholders such as the IP address.
- Any additional PKI or supporting resources required for first-boot initialization.

## Usage:
- The first-boot script is designed to run once during the initial startup of the appliance.
- The script automatically detects if cloud-init has already provided a valid configuration. If a configuration is detected, the script will skip the bootstrap process but still clean up the setup folder.
- All generated certificates and keys reside in /etc/etcd/pki.
- After execution, the setup folder is removed to maintain appliance immutability.

## Important Notes:
- The appliance assumes that the absence of a client listen URL other than 127.0.0.1 indicates no injected configuration.
- Operators should not modify or manually remove files in the setup folder prior to first boot.
- Any errors during first-boot initialization are logged in /root/setup.log until the folder is removed.
- This folder and its contents are only intended for first-boot initialization; they do not need to persist after setup completes.