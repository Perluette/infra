# RUNBOOK - ETCD PEERS & CLIENT CERTIFICATE REQUEST AND RENEWAL

## Purpose
This runbook describes how Kubernetes master nodes obtain and renew their etcd client certificates.
It is intended for administrators and operators interacting with the system, not for modifying it.

## Overview
Each Kubernetes master node is responsible for generating its own private key and certificate signing request (CSR).
The etcd cluster provides a signing endpoint that returns a short‑lived client certificate.

No manual approval or intervention is required.

## Prerequisites
The requesting node must:
- Be connected to the control plane network
- Have SSH connectivity to the etcd signing endpoint
- Know its own master name in the form kubemaster-<id>
- The private key must never leave the node.

## Initial Certificate Request
- Generate a private key locally on the master node.
- Generate a CSR using the master name as the Common Name.
- Base64‑encode the CSR.
- Send the encoded CSR to the signing endpoint via SSH.
- Store the returned certificate locally.
Only the certificate is returned. The private key remains local.

## Certificate Renewal
Certificates are short‑lived and must be renewed automatically.

The renewal process is identical to the initial request and reuses the existing private key.
A new CSR is generated and submitted before expiration.

There is no manual revocation. Expired certificates are automatically rejected by etcd.

## Failure Handling
If certificate issuance fails:
- Verify network connectivity to the signing endpoint
- Verify the master name format
- Verify system time synchronization

If renewal fails and the certificate expires, the master node must request a new certificate before reconnecting to etcd.

## What This System Does Not Do
- It does not store issued certificates
- It does not revoke certificates
- It does not authenticate individual nodes beyond network placement
- It does not provide interactive access to the signing system

## Support and Escalation
If certificate issuance consistently fails or behavior differs from this runbook, consult the SECURITY documentation before escalating.

Changes to the signing mechanism are not supported without explicit administrative approval.

## Operations
In order to make maintenance easier and human factor safer, standard operations had been scripted. To prevent any unintended automation, any non-replayable script is destroyed once executed (self-destructed).

### Init an etcd cluster
At first boot, execute the `/root/setup/first-boot.sh init` (non-replayable) command. This ends up with making this instance as a single node etcd cluster.

Once this stage completed, the `/etc/etcd/pki/ca.key` is the single and only key authenticating against the etcd operations authority. Save it securely !

### Joining an etcd cluster member
For any new instance of etcd you whish to join to the cluster, at first boot, execute the `/root/setup/first-boot.sh join --signer-ip=<etcd_leader_ip>` (non-replayable) where `etcd_leader_ip` point the address of the instance where init command had been invoked (the only one holding the pki `ca.key`)

*Note*: In the specific case of adding a second member to a single node etcd cluster creates a temporary service disruption because of quorum calculation. Depending on etcd data amount and underlaying hardware capabilities, this disruption is intended to remain under 5s at most.

### Request the etcd member list
To assure High-Availability, it is welcome to use the full range of participating client adresses members of the etcd cluster. Retrieving the members can be accomplished by issuing the following SSH command:
```bash
ssh signer@<etcd_leader_ip> "get-peers"
```

### Request the CertificateAuthority certificate
The CA certificate is required to generate a ClientSigningRequest against the etcd Authority. This certificate is assumed as stable and thus can be retrieved in a "one-shot" procedure. Nevertheless, the retriving command can be invoked as often as needed:
```bash
ssh signer@<etcd_leader_ip> "get-certificate" > ca.crt
```

### Request a client certificate
A client certificate can be issued for a very limited amount of time (by default, 24h). Performing a request for a client certificate can be made from the client itself through an ssh command as follow:
```bash
base64 < client.csr | ssh signer@<etcd_leader_ip> "$HOSTNAME" > client.crt
```

End of document.
