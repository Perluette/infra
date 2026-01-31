SECURITY OVERVIEW – ETCD CLIENT CERTIFICATE SIGNING AUTHORITY

Purpose
This document describes the security model, threat assumptions, and operational guarantees of the etcd client certificate signing mechanism used to bootstrap and operate Kubernetes control plane nodes.
It is intended as the authoritative reference for understanding why the system is designed this way and which questions are considered out of scope by design.

Scope
This mechanism exists solely to issue short‑lived etcd client certificates for Kubernetes master nodes.
It is not a general‑purpose PKI, nor a user‑facing certificate authority.
Each etcd cluster is bound to exactly one Kubernetes cluster.

High‑Level Architecture
A minimal signing service runs on etcd nodes.
Kubernetes master nodes generate their own private keys locally, create a CSR, and request a signed certificate via SSH.
The signing service enforces strict constraints on certificate content and lifetime.

The signing mechanism is fully automated and stateless.

Trust Model
Trust is explicitly based on network isolation rather than on individual host identities.

Any node that is able to reach the signing endpoint from the designated control plane network is considered legitimate by design.
This assumption is intentional and aligned with the operational constraints of a SingleOps environment.

The system does not attempt to authenticate individual nodes beyond network placement.

Threat Model
The system is designed to protect against the following:

Accidental exposure of the CA private key

Command injection or arbitrary code execution

Unauthorized certificate modification

Persistence or escalation via the signing mechanism

Long‑lived credential compromise

The system explicitly does not attempt to protect against:

Full compromise of the isolated control plane network

Malicious root access on the signing host

Advanced persistent threats targeting the physical infrastructure

Security relies on layered defense and short credential lifetime, not on absolute prevention.

CA Private Key Handling
The CA private key is stored locally on the etcd nodes and never leaves the system.
It is readable only by a dedicated signing user.

The key cannot be displayed, copied, or exfiltrated via SSH because:

SSH access is restricted to a forced command

No interactive shell is available

No TTY, forwarding, or tunnels are permitted

The private key is used only in memory by OpenSSL during signing operations.

SSH Enforcement
All signing requests are handled through an SSH user configured with ForceCommand.
Regardless of the command requested by the client, only the signing script is executed.

Interactive access, shell execution, port forwarding, and environment manipulation are fully disabled.
This guarantees that SSH is used strictly as a transport mechanism, not as an execution environment.

Script Integrity
The signing script is immutable at the filesystem level.
Once deployed and validated, it cannot be modified, replaced, or deleted, even by root, without explicit administrative action.

This prevents both accidental changes and post‑compromise tampering.

Input Validation and Injection Prevention
All user‑supplied input is strictly validated.

The requesting node identifier must match a predefined naming pattern.
Any deviation results in immediate rejection.

The certificate signing request is treated as opaque data and is never interpreted or executed.
No dynamic shell evaluation is performed at any stage.

The script contains no eval statements, no dynamic command construction, and no user‑controlled execution paths.

As a result, there is no viable command injection or code execution vector.

Certificate Constraints
All certificates issued by the signing service enforce:

Client authentication usage only

No CA capabilities

A short, fixed validity period

Explicit subject and SAN values controlled by the signer

Client‑provided extensions are ignored and overridden.

Certificate Lifetime and Revocation
Certificates are intentionally short‑lived.
The system does not implement certificate revocation lists or OCSP.

This is a conscious design choice.

Risk is mitigated by:

Short certificate validity

Automated renewal

Immutable infrastructure principles

Network segmentation

A compromised certificate is expected to expire quickly and become unusable without operator intervention.

Operational Simplicity
The design prioritizes reliability, clarity, and maintainability over theoretical maximal security.

All components are simple, observable, and auditable.
No external dependencies or distributed state are required.

This approach minimizes operational risk in a SingleOps environment and reduces the likelihood of misconfiguration.

Security Boundaries
The following are considered hard security boundaries:

Network segmentation between infrastructure tiers

Forced SSH command execution

Immutable signing logic

Short‑lived credentials

The following are not security boundaries:

Host identity beyond network placement

SSH user identity

Persistent node credentials

Conclusion
This system provides a controlled, minimal, and auditable mechanism for issuing etcd client certificates under strict operational constraints.

It is secure by design, proportionate to the threat model, and intentionally avoids unnecessary complexity.

Questions that assume a different trust model, a multi‑operator environment, or long‑lived credentials are out of scope by design and should be evaluated against those different assumptions before being raised.

End of document.