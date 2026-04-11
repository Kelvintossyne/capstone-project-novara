# Novara TaskApp — Operations Runbook

## 1. Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.5.0 installed
- Kops installed
- kubectl installed
- Domain registrar access for deploywithme.xyz

---

## 2. Deploying the Application from Scratch

### Step 1: Clone the Repository

git clone https://github.com/Kelvintossyne/capstone-project-novara.git
cd capstone-project-novara

### Step 2: Provision Base Infrastructure with Terraform

cd terraform
terraform init
terraform apply

Note the outputs — you will need the Route53 nameservers and S3 bucket name.

### Step 3: Delegate DNS at Your Registrar

Log into your domain registrar and update the nameservers for deploywithme.xyz to:

- ns-75.awsdns-09.com
- ns-1333.awsdns-38.org
- ns-1998.awsdns-57.co.uk
- ns-635.awsdns-15.net

Wait 5-15 minutes for DNS propagation before proceeding.

Verify delegation:
dig NS deploywithme.xyz

### Step 4: Create the Kubernetes Cluster with Kops

export KOPS_STATE_STORE=s3://novara-kops-state-production
export CLUSTER_NAME=k8s.deploywithme.xyz

kops create cluster \
  --name=${CLUSTER_NAME} \
  --state=${KOPS_STATE_STORE} \
  --zones=us-east-1a,us-east-1b,us-east-1c \
  --master-zones=us-east-1a,us-east-1b,us-east-1c \
  --master-count=3 \
  --node-count=3 \
  --master-size=t3.medium \
  --node-size=t3.medium \
  --topology=private \
  --networking=calico \
  --dns-zone=deploywithme.xyz \
  --yes

kops update cluster ${CLUSTER_NAME} --yes
kops validate cluster --wait 10m

### Step 5: Deploy the Application

kubectl apply -f k8s/base/sealed-secrets/controller.yaml
kubectl apply -f k8s/base/cert-manager/
kubectl apply -k k8s/overlays/production/

### Step 6: Verify All Pods Are Running

kubectl get pods -n taskapp

### Step 7: Verify HTTPS Endpoints

curl https://taskapp.deploywithme.xyz
curl https://api.deploywithme.xyz/api/health

---

## 3. Scaling the Cluster

### Scale Worker Nodes

kops edit ig nodes-us-east-1a --state=${KOPS_STATE_STORE}

Change maxSize and minSize values, then apply:

kops update cluster ${CLUSTER_NAME} --yes
kops rolling-update cluster ${CLUSTER_NAME} --yes

### Scale Application Pods

kubectl scale deployment frontend -n taskapp --replicas=3
kubectl scale deployment backend -n taskapp --replicas=3

---

## 4. Rotating Secrets

### Rotate Database Password

NEW_PASSWORD=$(openssl rand -base64 24)

kubectl create secret generic postgres-secret \
  --from-literal=POSTGRES_PASSWORD=${NEW_PASSWORD} \
  --from-literal=DATABASE_URL=postgresql://taskapp:${NEW_PASSWORD}@postgres:5432/taskapp \
  -n taskapp \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl rollout restart deployment/backend -n taskapp
kubectl rollout status deployment/backend -n taskapp

---

## 5. Zero-Downtime Deployment

kubectl set image deployment/frontend frontend=kelvintossyne/taskapp-frontend:new-tag -n taskapp
kubectl set image deployment/backend backend=kelvintossyne/taskapp-backend:new-tag -n taskapp

kubectl rollout status deployment/frontend -n taskapp
kubectl rollout status deployment/backend -n taskapp

To rollback:

kubectl rollout undo deployment/frontend -n taskapp
kubectl rollout undo deployment/backend -n taskapp

---

## 6. Troubleshooting Common Failures

### Cluster Not Validating

kops validate cluster --state=${KOPS_STATE_STORE}

### Pod Stuck in Pending

kubectl describe pod <pod-name> -n taskapp

Common causes:
- Insufficient resources: kubectl describe nodes
- PVC not binding: kubectl get pvc -n taskapp
- Image pull error: verify image tag exists in Docker Hub

### Pod Stuck in CrashLoopBackOff

kubectl logs <pod-name> -n taskapp
kubectl logs <pod-name> -n taskapp --previous

### Database Not Connecting

kubectl exec -it <backend-pod> -n taskapp -- env | grep DATABASE_URL
kubectl get secret postgres-secret -n taskapp -o jsonpath='{.data}'

### SSL Certificate Not Issuing

kubectl describe certificate taskapp-tls -n taskapp
kubectl logs -n cert-manager deployment/cert-manager

### DNS Not Resolving

dig taskapp.deploywithme.xyz
dig api.deploywithme.xyz

aws route53 list-resource-record-sets --hosted-zone-id <zone-id>

---

## 7. Destroying the Infrastructure

### Step 1: Delete the Kubernetes Cluster

kops delete cluster ${CLUSTER_NAME} --state=${KOPS_STATE_STORE} --yes

### Step 2: Empty the Kops S3 Bucket

aws s3 rm s3://novara-kops-state-production --recursive

aws s3api delete-objects \
  --bucket novara-kops-state-production \
  --delete "$(aws s3api list-object-versions \
    --bucket novara-kops-state-production \
    --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' \
    --output json)"

### Step 3: Clear Route53 Non-Default Records

Remove any CNAME and subdomain NS records from the hosted zone before destroying.

### Step 4: Destroy Terraform Infrastructure

cd terraform
terraform destroy

---

## 8. Backup and Recovery

### Verify etcd Backups

aws s3 ls s3://novara-kops-state-production/k8s.deploywithme.xyz/backups/

### Database Backup

kubectl exec -it postgres-<pod-id> -n taskapp -- \
  pg_dump -U taskapp taskapp > backup-$(date +%Y%m%d).sql

aws s3 cp backup-$(date +%Y%m%d).sql s3://novara-kops-state-production/db-backups/

### Restore Database from Backup

kubectl exec -i postgres-<pod-id> -n taskapp -- \
  psql -U taskapp taskapp < backup-20260409.sql

---

## 9. Health Checks

kops validate cluster
kubectl get nodes
kubectl get pods -n taskapp
kubectl get pvc -n taskapp
kubectl get certificate -n taskapp
curl -sk https://api.deploywithme.xyz/api/health
