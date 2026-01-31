# usr/local/bin scripts
This directory contains scripts included in the node images to perform key operational tasks during first boot or runtime.

These scripts are not intended for manual execution outside the defined workflows and are not copied into the image for end operators.

They are provided here for reference, maintenance, and developer understanding.

## Scripts overview

### 1. getEtcdClientCertificate
- Purpose: obtain a TLS client certificate for the local node to communicate securely with the etcd cluster.
- Functionality:
  1. Connects via SSH to the designated “master” etcd instance which holds the PKI.
  2. Retrieves the CA certificate (ca.crt) from the master etcd instance.
  3. Generates a local CSR (certificate signing request) for this node.
  4. Sends the CSR to the master etcd node for signing.
  5. Receives a signed certificate, enabling the local node to participate in etcd communication.
- Dependencies: must have network access to the master etcd node; expects the PKI and SSH access to be correctly configured, relies on the etcd instance built from `1002-etcd`.

###  2. getHaproxyconf_apiserver
- Purpose: generate the HAProxy configuration for connecting to Kubernetes control-plane nodes on port 6443.
- Functionality:
  - Queries the known control-plane nodes and outputs a valid HAProxy configuration.
  - Ensures load balancing and high availability for API server traffic.
- Dependencies: relies on the HAProxy instance built from `1000-ha-proxy`.

###  3. getHaproxyconf_edge
- Purpose: generate the HAProxy configuration for edge traffic (ports 80 and 443) directed to NodePort services over the Weave network.
- Functionality:
  - Collects NodePort endpoints and outputs a valid HAProxy configuration for edge traffic.
- Dependencies: also relies on the HAProxy instance built from `1000-ha-proxy`.

## Design philosophy
- These scripts encapsulate critical operational procedures without requiring operator intervention.
- They maintain idempotence and repeatability, ensuring nodes can be safely bootstrapped or rejoined to the cluster.
- By centralizing these procedures, they reduce the risk of manual errors and simplify first-boot workflows.

## Maintenance notes
- All scripts are versioned alongside the image build code.
- Changes to the underlying PKI, control-plane, or HAProxy architecture must be reflected in these scripts.
- Scripts are intended for developers maintaining or extending image build procedures; operational staff do not interact with them directly.