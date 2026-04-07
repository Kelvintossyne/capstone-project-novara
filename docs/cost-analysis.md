# Cost Analysis - TaskApp AWS Infrastructure

## Monthly Cost Estimate

### Kubernetes Control Plane (Masters)
| Resource | Type | Count | Unit Cost | Monthly Cost |
|---|---|---|---|---|
| Master nodes | t3.medium | 3 | $30.37 | $91.11 |
| Master EBS volumes | gp3 20GB | 3 | $1.60 | $4.80 |

### Worker Nodes
| Resource | Type | Count | Unit Cost | Monthly Cost |
|---|---|---|---|---|
| Worker nodes | t3.medium | 3 | $30.37 | $91.11 |
| Worker EBS volumes | gp3 20GB | 3 | $1.60 | $4.80 |

### Networking
| Resource | Details | Monthly Cost |
|---|---|---|
| NAT Gateways | 3x (one per AZ) | $98.55 |
| NAT Gateway data | ~100GB/month | $4.50 |
| Load Balancer | Classic ELB | $18.00 |
| Elastic IPs | 3x | $0.00 (attached) |

### Storage
| Resource | Details | Monthly Cost |
|---|---|---|
| Postgres EBS | gp3 10GB | $0.80 |
| S3 kops state | ~1GB | $0.02 |
| S3 terraform state | ~1GB | $0.02 |
| S3 etcd backups | ~5GB/month | $0.12 |

### DNS
| Resource | Details | Monthly Cost |
|---|---|---|
| Route53 hosted zone | 1 zone | $0.50 |
| Route53 queries | ~1M queries | $0.40 |

---

## Total Monthly Estimate

| Category | Monthly Cost |
|---|---|
| Control Plane | $95.91 |
| Worker Nodes | $95.91 |
| Networking | $121.05 |
| Storage | $0.96 |
| DNS | $0.90 |
| **Total** | **$314.73** |

---

## Cost Optimization Strategies

### Immediate savings
- Use spot instances for worker nodes (save ~70%)
- Estimated worker node cost with spots: ~$27.33/month
- Total with spot workers: ~$250.00/month

### Long term savings
- Reserved instances for masters (1 year): save ~40%
- Use t3.small for non-production environments
- Enable cluster autoscaler to scale down during off-peak hours

### AWS Free Tier
- New AWS accounts get 12 months free tier
- t2.micro/t3.micro instances free for 750 hours/month
- 5GB S3 storage free
- Note: This project exceeds free tier due to t3.medium instances

---

## Budget Alert Setup
```bash
aws budgets create-budget \
  --account-id YOUR_ACCOUNT_ID \
  --budget '{
    "BudgetName": "TaskApp-Monthly-Budget",
    "BudgetLimit": {
      "Amount": "50",
      "Unit": "USD"
    },
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST"
  }'
```

---

## AWS Calculator Reference
- Calculator URL: https://calculator.aws/pricing/2/home
- Estimated using us-east-1 region pricing as of 2024
- Actual costs may vary based on data transfer and usage patterns
