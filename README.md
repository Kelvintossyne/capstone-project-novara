# Novara TaskApp — Production AWS Deployment

A cloud-native task management application deployed on a production-grade,
highly available Kubernetes cluster on AWS.

**Live:** https://taskapp.deploywithme.xyz
**API:** https://api.deploywithme.xyz
**Cluster:** k8s.deploywithme.xyz (us-east-1)

---

## Architecture at a Glance

Internet → Route53 → ELB → NGINX Ingress (SSL) → Frontend / Backend → PostgreSQL (EBS)
                                                        ↑
                                              Private subnets, 3 AZs
                                              3 masters + 3 workers (Kops)

- **Infrastructure:** Terraform (VPC, IAM, DNS, S3) + Kops (Kubernetes cluster)
- **Kubernetes Version:** v1.28.0
- **Networking:** Private topology, 3 NAT Gateways (one per AZ), no public node IPs
- **SSL:** cert-manager + Let's Encrypt (auto-renewing)
- **Secrets:** Bitnami Sealed Secrets (encrypted at rest, safe to commit)
- **GitOps:** ArgoCD for automated deployments
- **HA:** 3-master etcd quorum, workers spread across 3 AZs, zero-downtime rolling updates

---

## Repository Structure

capstone-project-novara/
├── terraform/                    # AWS infrastructure as code
│   ├── modules/
│   │   ├── vpc/                  # VPC, subnets, NAT gateways, security groups
│   │   ├── iam/                  # IAM roles, instance profiles, kops user
│   │   ├── dns/                  # Route53 hosted zone
│   │   └── s3/                   # Kops state store bucket
│   ├── backend.tf                # Remote state (S3 + DynamoDB locking)
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── kops/                         # Kops cluster specifications
│   └── cluster.yaml              # Full cluster definition
├── k8s/
│   ├── base/                     # Reusable Kubernetes manifests
│   │   ├── frontend.yaml
│   │   ├── frontend-service.yaml
│   │   ├── backend.yaml
│   │   ├── backend-service.yaml
│   │   ├── postgres.yaml
│   │   ├── postgres-pvc.yaml
│   │   ├── postgres-service.yaml
│   │   ├── ingress.yaml
│   │   ├── configmap.yaml
│   │   ├── sealed-secrets/       # Encrypted secrets (safe to commit)
│   │   ├── cert-manager/         # ClusterIssuer and StorageClass
│   │   └── argocd/               # ArgoCD installation and app definition
│   └── overlays/
│       └── production/           # AWS-specific patches (PVC, ingress)
├── scripts/
│   ├── deploy.sh                 # Full automated deployment
│   ├── destroy.sh                # Teardown with database backup
│   └── validate.sh               # Submission validation checks
└── docs/
    ├── architecture.md           # Design decisions and diagrams
    ├── runbook.md                 # Operational procedures
    ├── cost-analysis.md          # Monthly cost breakdown
    └── screenshots/              # Validation evidence

---

## Quickstart

### Prerequisites

Install required tools:
brew install awscli terraform kops kubectl kubeseal jq helm

Configure AWS credentials:
aws configure

### Deploy

Full deployment (~25 minutes):
./scripts/deploy.sh

After Terraform completes, update your domain registrar NS records
with the nameservers shown in the output, then press Enter to continue.

### Validate

./scripts/validate.sh
Produces a validation report: validation-report-YYYYMMDD-HHMMSS.txt

### Destroy

./scripts/destroy.sh
Takes a final database backup before destroying everything.

---

## Application Components

| Component | Image                                 | Replicas | Memory Limit |
|-----------|---------------------------------------|----------|--------------|
| Frontend  | kelvintossyne/taskapp-frontend:1.0.0  | 2        | -            |
| Backend   | kelvintossyne/taskapp-backend:1.0.0   | 2        | 526Mi        |
| Database  | PostgreSQL                            | 1        | -            |

---

## Key Design Decisions

| Decision                         | Rationale                                                    |
|----------------------------------|--------------------------------------------------------------|
| 3 NAT Gateways (one per AZ)      | Redundant egress — no single point of failure                |
| Private node topology            | No node has a public IP; only ELB is internet-facing         |
| Sealed Secrets                   | Encrypted secrets safe to store in Git                       |
| maxUnavailable: 0 rolling update | Zero-downtime deploys guaranteed                             |
| EBS Retain reclaim policy        | Database survives pod deletion                               |
| Separate Kops S3 bucket          | Separation of concerns from Terraform state                  |
| 3 control plane nodes            | etcd quorum survives loss of one master                      |
| cert-manager + Let's Encrypt     | Automated SSL with auto-renewal, no manual certificate work  |
| kops 1.28 + Ubuntu 22.04         | Proven stable combination for production clusters            |

---

## Security Notes

- No AWS credentials hardcoded anywhere in this repository
- All secrets use Sealed Secrets (asymmetric encryption tied to the cluster)
- Database credentials never committed in plaintext
- Nodes in private subnets — internet access is outbound-only via NAT
- Kubernetes API server is internal-only (not publicly accessible)
- etcd ports restricted to VPC CIDR only
- VPC Flow Logs enabled with 30-day retention

---

## Validation Evidence

| Check                         | Evidence                                          |
|-------------------------------|---------------------------------------------------|
| kops validate cluster         | docs/screenshots/01-kops-validate-cluster.png     |
| kubectl get nodes -o wide     | docs/screenshots/02-kubectl-get-nodes-wide.png    |
| All pods Running across AZs   | docs/screenshots/03-kubectl-get-pods-wide.png     |
| Live API health check + HTTPS | docs/screenshots/04-api-health-check.png          |
| TLS certificate Ready         | docs/screenshots/05-tls-certificate.png           |
| Frontend HTTPS                | docs/screenshots/06-frontend-https.png            |
| cert-manager running          | docs/screenshots/07-cert-manager-running.png      |
| kops validate + nodes         | docs/screenshots/08-kops-validate-combined.png    |
| kubectl get nodes             | docs/screenshots/09-kubectl-get-nodes.png         |
| Pods spread across AZs        | docs/screenshots/10-pods-across-azs.png           |

---

## Cost

~$318.76/month at full scale. See docs/cost-analysis.md for full breakdown.

**Remember to run ./scripts/destroy.sh when not actively demonstrating.**
