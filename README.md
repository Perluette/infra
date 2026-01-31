# Repository purpose and scope
This repository hosts the infrastructure code and operational assets used to build and operate a personal, enterprise-grade Kubernetes platform.

The platform is deployed on a single physical server and is fully self-operated.
It is designed with production-grade principles in mind (reliability, security, reproducibility, operability), while explicitly accounting for the constraints of a solo operator.

This is not a generic “homelab” repository, nor a reference architecture meant to be universally reusable.
It is a concrete implementation, shaped by real operational trade-offs and long-term maintainability concerns.

## Context
The underlying environment is a personal server running Proxmox as a virtualization layer, with sufficient compute, memory and network capacity to host a multi-node Kubernetes cluster.

Networking is segmented using VLANs and enforced through a dedicated firewall (pfSense).
All platform components are deployed on top of this foundation, with a clear separation between infrastructure bootstrap, node preparation, and Kubernetes-level services.

The author operates this platform alone.
This constraint is considered a first-class design input and has influenced most architectural decisions.

## Goals
The primary goals of this project are:
- Build and operate a Kubernetes platform using enterprise-grade patterns and components.
- Keep the system understandable, debuggable and operable by a single person.
- Favor explicit configuration and reproducibility over automation opacity.
- Provide clear operational documentation (runbooks, upgrade paths, bootstrap steps).
- Allow incremental evolution over time without requiring disruptive rewrites.

## Non-goals
This project does not aim to:
- Abstract complexity behind opinionated frameworks.
- Optimize for minimal hardware usage at all costs.
- Serve as a general-purpose template for third parties.

Some decisions may appear conservative or verbose by design.

They reflect operational preferences rather than theoretical optimality.

## Repository structure
The repository is organized by functional domains and maturity stages, rather than by tools alone.

High-level structure:
- Bootstrap and anchoring components (external dependencies, initial trust, foundations).
- Node seeding and operating system preparation.
- Core Kubernetes infrastructure services.
- Platform-level services deployed on top of Kubernetes.

Each major component lives in its own directory and is documented locally.

The root README intentionally stays high-level; implementation details are documented closer to the code.

## Operational philosophy
A few guiding principles underpin this repository:
- Clarity over cleverness.
- Explicit configuration over implicit defaults.
- Operational predictability over feature density.
- Documentation as an operational artifact, not an afterthought.

Runbooks, first-boot scripts and upgrade notes are treated as part of the system, not as auxiliary files.

## Iteration model

The platform is developed iteratively.

Some components reflect the current operational state, while others prepare future iterations.
This is intentional: the repository captures both what is running today and what is being prepared for tomorrow.

Not all directories represent “finished” systems.
Stability and completeness vary by component and are expected to evolve over time.

## Prerequisites
To make sense of this repository, the reader is expected to be familiar with:
- Linux system administration.
- Basic networking concepts (routing, VLANs, firewalls).
- Kubernetes fundamentals.
- Virtualization concepts, particularly Proxmox.

A Proxmox environment capable of hosting a multi-node Kubernetes cluster is assumed.

## Intended audience
This repository is primarily maintained for personal use.

It may be of interest to:
- Platform engineers or SREs operating small but serious Kubernetes environments.
- Engineers curious about applying production patterns in constrained or solo-operated contexts.

Readers should expect to adapt ideas rather than reuse code verbatim.

## Final note

This repository reflects practical experience, constraints, and trade-offs accumulated over time.
It is meant to be read as an operational narrative as much as a codebase.

Questions, alternative approaches and improvements are expected parts of its evolution.