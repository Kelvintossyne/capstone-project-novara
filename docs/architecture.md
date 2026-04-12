# Novara TaskApp — Architecture Design

## 1. Overview

Novara is a cloud-native task management application deployed on a production-grade Kubernetes cluster on AWS. The infrastructure is fully defined as code using Terraform and Kops, with a private network topology, multi-master high availability, and automated SSL/TLS termination via cert-manager.

- **Domain:** deploywithme.xyz
- **Region:** us-east-1
- **Kubernetes Version:** v1.28.0
- **Cluster Name:** k8s.deploywithme.xyz

---

## 2. Architecture Diagram
                    ┌─────────────────────────────────────────┐
                    │           Route53 (deploywithme.xyz)    │
                    │  taskapp.deploywithme.xyz → ELB CNAME   │
                    │  api.deploywithme.xyz     → ELB CNAME   │
                    └──────────────────┬──────────────────────┘
                                       │
                    ┌──────────────────▼──────────────────────┐
                    │         AWS Elastic Load Balancer       │
                    │         (NGINX Ingress Controller)      │
                    │         SSL Termination via cert-manager│
                    └──────────┬───────────────┬──────────────┘
                               │               │
           ┌───────────────────▼───┐   ┌───────▼───────────────┐
           │  Frontend Service     │   │  Backend Service      │
           │  (React, 2 replicas)  │   │  (Flask, 2 replicas)  │
           └───────────────────────┘   └───────────────────────┘
                                                   │
                                       ┌───────────▼───────────┐
                                       │  PostgreSQL Service   │
                                       │  (EBS Persistent Vol) │
                                       └───────────────────────┘

---

## 3. Network Architecture

### 3.1 VPC Design

| Parameter          | Value                               |
|--------------------|-------------------------------------|
| VPC CIDR           | 10.0.0.0/16                         |
| Region             | us-east-1                           |
| Availability Zones | us-east-1a, us-east-1b, us-east-1c  |
| Total Subnets      | 6 (3 public, 3 private)             |

**CIDR Sizing Rationale:** A /16 provides 65,536 addresses, giving ample room for cluster growth. Each /24 subnet provides 256 addresses per AZ, sufficient for the current node count with headroom for autoscaling.

### 3.2 Subnet Allocation

| Subnet             | CIDR          | AZ         | Type    | Purpose                      |
|--------------------|---------------|------------|---------|------------------------------|
| public-us-east-1a  | 10.0.1.0/24   | us-east-1a | Public  | NAT Gateway, Load Balancer   |
| public-us-east-1b  | 10.0.2.0/24   | us-east-1b | Public  | NAT Gateway, Load Balancer   |
| public-us-east-1c  | 10.0.3.0/24   | us-east-1c | Public  | NAT Gateway, Load Balancer   |
| private-us-east-1a | 10.0.10.0/24  | us-east-1a | Private | Kubernetes masters and nodes |
| private-us-east-1b | 10.0.11.0/24  | us-east-1b | Private | Kubernetes masters and nodes |
| private-us-east-1c | 10.0.12.0/24  | us-east-1c | Private | Kubernetes masters and nodes |

### 3.3 Routing and Egress

- **Internet Gateway** attached to VPC for public subnet internet access
- **3 NAT Gateways** (one per AZ) provide redundant outbound internet for private subnets — eliminates single point of failure for egress traffic
- Each private subnet has its own route table pointing to its local NAT Gateway
- Kubernetes masters and worker nodes have **no public IPs**

### 3.4 Security Groups

| Security Group | Inbound Rules                                                                           | Purpose                         |
|----------------|-----------------------------------------------------------------------------------------|---------------------------------|
| masters-sg     | Port 6443 from VPC CIDR, Port 2379-2380 from VPC CIDR, self                            | Kubernetes API server and etcd  |
| nodes-sg       | Port 443 from internet, Port 80 from internet, NodePort 30000-32767 from VPC CIDR, self | Worker node ingress traffic     |

VPC Flow Logs enabled with 30-day retention in CloudWatch for network audit trail.

---

## 4. Kubernetes Cluster

### 4.1 Cluster Specifications

| Parameter           | Value                              |
|---------------------|------------------------------------|
| Cluster Name        | k8s.deploywithme.xyz               |
| Kubernetes Version  | v1.28.0                            |
| Provisioner         | Kops                               |
| Topology            | Private (nodes in private subnets) |
| Control Plane Nodes | 3 x t3.medium (one per AZ)         |
| Worker Nodes        | 3 x t3.medium (one per AZ)         |
| Total Nodes         | 6                                  |

### 4.2 High Availability Strategy

The control plane runs across all three availability zones with one master per AZ. etcd runs as a distributed quorum across all three masters. With 3 masters, the cluster tolerates the loss of one master and maintains quorum (2 of 3 nodes still available). Worker nodes are also spread one per AZ, ensuring application pods continue running even if one AZ becomes unavailable.

### 4.3 Instance Groups

| Instance Group           | Role         | Machine Type | AZ         |
|--------------------------|--------------|--------------|------------|
| control-plane-us-east-1a | ControlPlane | t3.medium    | us-east-1a |
| control-plane-us-east-1b | ControlPlane | t3.medium    | us-east-1b |
| control-plane-us-east-1c | ControlPlane | t3.medium    | us-east-1c |
| nodes-us-east-1a         | Node         | t3.medium    | us-east-1a |
| nodes-us-east-1b         | Node         | t3.medium    | us-east-1b |
| nodes-us-east-1c         | Node         | t3.medium    | us-east-1c |

---

## 5. Application Layer

### 5.1 Components

| Component | Technology     | Replicas | Memory Request/Limit |
|-----------|----------------|----------|----------------------|
| Frontend  | React          | 2        | Defined in manifest  |
| Backend   | Flask (Python) | 2        | 526Mi / 526Mi        |
| Database  | PostgreSQL     | 1        | Defined in manifest  |

### 5.2 Storage

PostgreSQL uses an EBS-backed PersistentVolume with a Retain reclaim policy, ensuring data survives pod deletion and rescheduling. The volume persists independently of the pod lifecycle.

### 5.3 Ingress and SSL

NGINX Ingress Controller handles all inbound traffic with the following routing rules:

- https://taskapp.deploywithme.xyz → Frontend Service
- https://api.deploywithme.xyz → Backend Service

cert-manager automatically provisions and renews TLS certificates. HTTP traffic is redirected to HTTPS at the ingress level.

---

## 6. Infrastructure as Code

### 6.1 Terraform Structure

terraform/
├── main.tf               # Root module
├── variables.tf          # Input variables with validation
├── outputs.tf            # Output definitions
├── backend.tf            # Remote state (S3 + DynamoDB locking)
└── modules/
    ├── vpc/              # VPC, subnets, NAT gateways, routing, security groups
    ├── iam/              # IAM roles and instance profiles for kops
    ├── dns/              # Route53 hosted zone
    └── s3/               # Kops state store bucket

### 6.2 Remote State

Terraform state is stored remotely in S3 with DynamoDB state locking to prevent concurrent modifications. The DynamoDB table (novara-terraform-locks) ensures only one operator can modify infrastructure at a time.

### 6.3 Kops State Store

Kops cluster state is stored in a dedicated S3 bucket (novara-kops-state-production) separate from the Terraform state bucket, following the principle of separation of concerns.

---

## 7. Security Model

### 7.1 IAM

- Separate IAM roles for cluster creation and cluster operations
- EC2 instance profiles attached to nodes — no hardcoded credentials
- Least-privilege policies scoped to required actions only
- No root account usage

### 7.2 Network Security

- Masters and workers placed in private subnets with no public IPs
- API server (port 6443) accessible only within VPC CIDR
- etcd ports (2379-2380) restricted to VPC CIDR
- NodePort range restricted to VPC CIDR

### 7.3 Secrets Management

- Database credentials stored as Kubernetes Secrets
- Secrets never committed to Git in plaintext
- Kubernetes Secrets encrypted at rest

### 7.4 TLS

- Valid SSL certificates via cert-manager (Let's Encrypt)
- Auto-renewal before expiry
- HTTP to HTTPS redirect enforced at ingress

---

## 8. DNS Architecture

The domain deploywithme.xyz is registered at an external registrar. DNS management is delegated to AWS Route53 by pointing the registrar's nameservers to the Route53 hosted zone nameservers:

- ns-29.awsdns-03.com
- ns-817.awsdns-38.net
- ns-1087.awsdns-07.org
- ns-1888.awsdns-44.co.uk

Route53 manages all DNS records including the subdomain delegation for k8s.deploywithme.xyz used internally by Kops.

---

## 9. Monitoring and Observability

- **Prometheus** — cluster and application metrics collection
- **Grafana** — metrics visualization and dashboards
- **CloudWatch** — AWS-level logs and VPC flow logs (30-day retention)
- **Liveness and Readiness Probes** — on all application containers for automatic pod recovery

---

## 10. Design Decisions

| Decision                | Choice                               | Rationale                                                  |
|-------------------------|--------------------------------------|------------------------------------------------------------|
| VPC CIDR                | 10.0.0.0/16                          | Provides 65k addresses for future growth                   |
| 3 NAT Gateways          | One per AZ                           | Eliminates NAT as single point of failure                  |
| Private topology        | Masters and nodes in private subnets | Security best practice, no direct internet exposure        |
| t3.medium instances     | Control plane and workers            | Balance of cost and performance for capstone workload      |
| Separate Kops S3 bucket | Separate from Terraform state        | Separation of concerns between IaC state and cluster state |
| EBS Retain policy       | Database persistent volume           | Prevents accidental data loss on pod deletion              |
| cert-manager            | SSL termination                      | Automated certificate provisioning and renewal             |
