# Novara TaskApp — Cost Analysis

## 1. Infrastructure Overview

All resources deployed in AWS us-east-1 region.
Cluster: 3 control plane nodes + 3 worker nodes (t3.medium)
Storage: EBS gp2 volumes for PostgreSQL (10Gi) and node root volumes
Networking: 3 NAT Gateways, 1 Application Load Balancer, Route53

---

## 2. Monthly Cost Breakdown

### 2.1 EC2 Instances (Kubernetes Nodes)

| Node Type     | Instance   | Count | Hourly Rate | Monthly Cost |
|---------------|------------|-------|-------------|--------------|
| Control Plane | t3.medium  | 3     | $0.0416     | $89.86       |
| Worker Nodes  | t3.medium  | 3     | $0.0416     | $89.86       |
| **Total EC2** |            | **6** |             | **$179.71**  |

t3.medium specs: 2 vCPU, 4GB RAM
Monthly hours: 730

### 2.2 Storage (EBS Volumes)

| Volume Purpose       | Type | Size  | Count | Rate/GB/month | Monthly Cost |
|----------------------|------|-------|-------|---------------|--------------|
| PostgreSQL PVC       | gp2  | 10Gi  | 1     | $0.10         | $1.00        |
| Node root volumes    | gp2  | 20Gi  | 6     | $0.10         | $12.00       |
| etcd volumes         | gp2  | 20Gi  | 3     | $0.10         | $6.00        |
| **Total EBS**        |      |       |       |               | **$19.00**   |

### 2.3 Networking

| Resource         | Unit          | Quantity | Rate       | Monthly Cost |
|------------------|---------------|----------|------------|--------------|
| NAT Gateway      | per gateway   | 3        | $32.40     | $97.20       |
| NAT Gateway data | per GB        | ~10GB    | $0.045     | $0.45        |
| Load Balancer    | per ALB       | 1        | $16.20     | $16.20       |
| LCU charges      | estimated     | -        | -          | $2.00        |
| Data transfer    | outbound ~5GB | -        | $0.09/GB   | $0.45        |
| **Total Network**|               |          |            | **$116.30**  |

Note: NAT Gateways are the most expensive component. 3 NAT Gateways are required
for high availability (one per AZ) to eliminate single points of failure.

### 2.4 DNS and Certificates

| Resource           | Cost          |
|--------------------|---------------|
| Route53 Hosted Zone| $0.50/month   |
| Route53 Queries    | ~$0.50/month  |
| SSL (Let's Encrypt)| Free          |
| **Total DNS**      | **$1.00**     |

### 2.5 S3 and DynamoDB

| Resource                  | Cost         |
|---------------------------|--------------|
| Kops state bucket         | ~$0.50/month |
| Terraform state bucket    | ~$0.50/month |
| DynamoDB lock table       | ~$0.25/month |
| **Total S3/DynamoDB**     | **$1.25**    |

### 2.6 CloudWatch

| Resource              | Cost         |
|-----------------------|--------------|
| VPC Flow Logs storage | ~$1.00/month |
| Log ingestion         | ~$0.50/month |
| **Total CloudWatch**  | **$1.50**    |

---

## 3. Total Monthly Cost Summary

| Category          | Monthly Cost |
|-------------------|--------------|
| EC2 Instances     | $179.71      |
| EBS Storage       | $19.00       |
| Networking        | $116.30      |
| DNS               | $1.00        |
| S3 / DynamoDB     | $1.25        |
| CloudWatch        | $1.50        |
| **TOTAL**         | **$318.76**  |

---

## 4. Cost Optimization Opportunities

### 4.1 Spot Instances for Worker Nodes (Bonus: -50% worker cost)
Replacing worker nodes with Spot instances could reduce worker node costs by
up to 70%. With proper interruption handling, this is safe for stateless workloads.

Estimated saving: ~$63/month
Risk: Spot interruptions require proper pod disruption budgets

### 4.2 Single NAT Gateway (Non-production only)
Reducing to 1 NAT Gateway saves ~$64/month but introduces a single point
of failure. Not recommended for production.

### 4.3 Reserved Instances (1-year commitment)
t3.medium reserved pricing reduces costs by ~40% for EC2.
Estimated saving: ~$72/month on EC2 alone

### 4.4 Smaller Control Plane Instances
Control plane nodes can run on t3.small instead of t3.medium for lighter workloads.
Estimated saving: ~$45/month

---

## 5. Cost Alerts

An AWS Budget alert is configured at $50 to warn before costs exceed expectations
during development and testing phases. For production, a $400 alert is recommended
to catch unexpected resource creation.

---

## 6. Cleanup Cost

Running terraform destroy and kops delete cluster brings monthly cost to $0.
The only residual cost is the Route53 hosted zone at $0.50/month if kept active.

Cleanup script: scripts/destroy.sh
