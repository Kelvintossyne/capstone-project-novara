# Taskapp - Architecture Documentation

## Overview
A containerized task management application deployed on Kubernetes.

## Local Development (Minikube)
- Frontend: React (Nginx) — 2 replicas
- Backend: Flask API — 2 replicas
- Database: PostgreSQL 15 — 1 replica
- Ingress: NGINX Ingress Controller
- Accessible at: http://taskapp.local:8080

## Kubernetes Features
- Rolling updates with zero downtime
- Resource limits and requests on all containers
- Liveness and readiness probes
- ConfigMap for non-sensitive configuration
- Secrets for sensitive credentials
- Replicas for high availability

## AWS Production (kops)
- Cluster: taskapp.k8s.local
- Master: 3x t3.medium
- Nodes: 3x t3.medium
- Networking: Calico CNI
- DNS: Route53
- State Store: S3

## Terraform Modules
- **vpc** — VPC, subnets, internet gateway, route tables
- **iam** — kops IAM role and instance profile
- **s3** — kops state bucket with versioning and encryption
- **dns** — Route53 hosted zone and records

## Repository Structure
```
capstone-project-novara/
├── README.md
├── ansible/          # Node hardening and configuration
├── docs/             # Architecture, runbook, cost analysis
├── docker-compose.yml # Local development
├── k8s/              # Kubernetes manifests
├── kops/             # Cluster configuration
├── scripts/          # Deploy and destroy scripts
├── taskapp_backend/  # Flask backend
├── taskapp_frontend/ # React frontend
└── terraform/        # AWS infrastructure
```
## High Availability Strategy
The cluster is distributed across 3 Availability Zones (AZs).
This means if one AZ goes down, the other two keep the application running.

- 3 masters spread across 3 AZs — if one master fails, etcd still has quorum
- 3 workers spread across 3 AZs — if one worker fails, pods reschedule to others
- 3 NAT Gateways — one per AZ so private nodes always have internet access
- Load balancer distributes traffic across all healthy nodes

## Security Model
- Passwords are stored using Sealed Secrets so they are encrypted in the repo
- Cluster nodes are in private subnets so they cannot be accessed directly from the internet
- To connect to the nodes you must go through a bastion host first
- SSH key authentication only — no password login allowed
- IAM roles used for AWS permissions — no hardcoded credentials

## CIDR Allocation
- VPC: `10.0.0.0/16` — gives 65,536 IP addresses for the whole network
- Public subnets: `10.0.1.0/24`, `10.0.2.0/24`, `10.0.3.0/24` — one per AZ, for NAT Gateways and load balancer
- Private subnets: `10.0.10.0/24`, `10.0.11.0/24`, `10.0.12.0/24` — one per AZ, for master and worker nodes
