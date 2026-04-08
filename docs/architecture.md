# CAPSTONE PROJECT NOVARA - ARCHITECTURE DESIGN

## 1. Overview
This project is a cloud-native task management application deployed on a Kubernetes cluster provisioned using Kops on AWS. The system is designed for high availability, scalability, and automation using Infrastructure as Code (Terraform) and configuration management (Ansible).

---

## 2. Architecture Diagram (Logical Flow)

User → Route53 DNS → Load Balancer (AWS ELB) → Kubernetes Ingress → Services → Pods (Frontend & Backend) → PostgreSQL Database

---

## 3. Infrastructure Components

### 3.1 AWS Cloud
- VPC (Networking layer)
- EC2 instances (Kubernetes nodes)
- S3 bucket (kops state store)
- IAM roles (permissions management)
- Route53 (DNS management)

---

### 3.2 Kubernetes Cluster (Kops)
- Master node (control plane)
- Worker nodes (application workloads)
- kube-apiserver
- controller-manager
- etcd (cluster state storage)

---

### 3.3 Application Layer

#### Frontend
- React / Web UI
- Exposed via LoadBalancer / Ingress

#### Backend
- Node.js / Express API
- Handles business logic and database communication

#### Database
- PostgreSQL
- Stores user data and tasks

---

## 4. Deployment Strategy
- Infrastructure provisioned using Terraform
- Cluster created using Kops
- Application deployed using Kubernetes manifests
- Configuration managed using Ansible
- Docker used for containerization

---

## 5. Networking
- VPC with public and private subnets
- Internet Gateway for external access
- Security Groups controlling traffic
- Kubernetes Ingress for routing

---

## 6. Security
- IAM roles for EC2 and Kops access
- Kubernetes RBAC enabled
- Secrets stored in Kubernetes Secrets
- Database credentials not hardcoded

---

## 7. Scalability
- Horizontal Pod Autoscaler (HPA)
- Multi-node Kubernetes cluster
- Load balancer distributes traffic

---

## 8. Monitoring
- Prometheus for metrics
- Grafana for visualization
- CloudWatch for AWS logs

---
