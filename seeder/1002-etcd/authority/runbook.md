RUNBOOK – ETCD CLIENT CERTIFICATE REQUEST AND RENEWAL

Purpose
This runbook describes how Kubernetes master nodes obtain and renew their etcd client certificates.
It is intended for administrators and operators interacting with the system, not for modifying it.

Overview
Each Kubernetes master node is responsible for generating its own private key and certificate signing request (CSR).
The etcd cluster provides a signing endpoint that returns a short‑lived client certificate.

No manual approval or intervention is required.

Prerequisites
The requesting node must:

Be connected to the control plane network

Have SSH connectivity to the etcd signing endpoint

Know its own master name in the form kubemaster-<id>

The private key must never leave the node.

Initial Certificate Request

Generate a private key locally on the master node.

Generate a CSR using the master name as the Common Name.

Base64‑encode the CSR.

Send the encoded CSR to the signing endpoint via SSH.

Store the returned certificate locally.

Only the certificate is returned. The private key remains local.

Certificate Renewal
Certificates are short‑lived and must be renewed automatically.

The renewal process is identical to the initial request and reuses the existing private key.
A new CSR is generated and submitted before expiration.

There is no manual revocation. Expired certificates are automatically rejected by etcd.

Failure Handling
If certificate issuance fails:

Verify network connectivity to the signing endpoint

Verify the master name format

Verify system time synchronization

If renewal fails and the certificate expires, the master node must request a new certificate before reconnecting to etcd.

What This System Does Not Do

It does not store issued certificates

It does not revoke certificates

It does not authenticate individual nodes beyond network placement

It does not provide interactive access to the signing system

Support and Escalation
If certificate issuance consistently fails or behavior differs from this runbook, consult the SECURITY documentation before escalating.

Changes to the signing mechanism are not supported without explicit administrative approval.

End of document.