# Novara TaskApp — Operations Runbook

## 1. Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.5.0 installed
- Kops 1.28.0 installed
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

Note the outputs — you will need the Route53 nameservers, VPC ID, subnet IDs and NAT Gateway IDs.

### Step 3: Delegate DNS at Your Registrar

Log into your domain registrar and update the nameservers for deploywithme.xyz to the
values below:

- ns-29.awsdns-03.com
- ns-817.awsdns-38.net
- ns-1087.awsdns-07.org
- ns-1888.awsdns-44.co.uk

Wait 5-15 minutes for DNS propagation before proceeding.

Verify delegation:
dig NS deploywithme.xyz @8.8.8.8

### Step 4: Create Subdomain Hosted Zone for Kops

aws route53 create-hosted-zone \
  --name k8s.deploywithme.xyz \
  --caller-reference $(date +%s) \
  --query "DelegationSet.NameServers" \
  --output json

Note the nameservers returned. Update the NS record in the parent zone:

aws route53 change-resource-record-sets \
  --hosted-zone-id <PARENT_ZONE_ID> \
  --change-batch '{
    "Changes": [{
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "k8s.deploywithme.xyz.",
        "Type": "NS",
        "TTL": 300,
        "ResourceRecords": [
          {"Value": "<NS1>"},
          {"Value": "<NS2>"},
          {"Value": "<NS3>"},
          {"Value": "<NS4>"}
        ]
      }
    }]
  }'

Verify:
dig NS k8s.deploywithme.xyz @8.8.8.8

### Step 5: Create the Kubernetes Cluster with Kops

IMPORTANT: Use kops 1.28.0 with Ubuntu 22.04 AMI only.
kops 1.28 does NOT support Ubuntu 24.04.

export KOPS_STATE_STORE=s3://novara-kops-state-production
export CLUSTER_NAME=k8s.deploywithme.xyz

Get your subnet and NAT Gateway IDs from terraform output, then create cluster using cluster.yaml:

kops create -f kops/cluster.yaml
kops update cluster k8s.deploywithme.xyz --yes

Wait 10-15 minutes for the cluster to come up, then validate:

kops validate cluster --wait 15m

Expected output:
Your cluster k8s.deploywithme.xyz is ready

### Step 6: Export Kubeconfig

kops export kubeconfig k8s.deploywithme.xyz --admin

### Step 7: Create Namespace and Apply Base Manifests

kubectl create namespace taskapp
kubectl apply -f k8s/base/configmap.yaml -n taskapp
kubectl apply -f k8s/base/postgres-pvc.yaml -n taskapp
kubectl apply -f k8s/base/postgres.yaml -n taskapp
kubectl apply -f k8s/base/postgres-service.yaml -n taskapp
kubectl apply -f k8s/base/backend.yaml -n taskapp
kubectl apply -f k8s/base/backend-service.yaml -n taskapp
kubectl apply -f k8s/base/frontend.yaml -n taskapp
kubectl apply -f k8s/base/frontend-service.yaml -n taskapp

### Step 8: Create Kubernetes Secrets

IMPORTANT: The backend requires DATABASE_PASSWORD as a separate key.

kubectl create secret generic postgres-secret \
  --from-literal=POSTGRES_DB=taskapp \
  --from-literal=POSTGRES_USER=taskapp \
  --from-literal='POSTGRES_PASSWORD=<your-password>' \
  -n taskapp

kubectl create secret generic taskapp-secret \
  --from-literal='SECRET_KEY=taskapp-secret-key-2026-production' \
  --from-literal='DATABASE_URL=postgresql://taskapp:<your-password>@postgres:5432/taskapp' \
  --from-literal='DATABASE_PASSWORD=<your-password>' \
  -n taskapp

### Step 9: Install NGINX Ingress Controller

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/aws/deploy.yaml

Wait for ingress controller to be ready:
kubectl get pods -n ingress-nginx

Get the external load balancer DNS:
kubectl get svc ingress-nginx-controller -n ingress-nginx

### Step 10: Create DNS Records for Application

cat > /tmp/route53-taskapp.json <<'DNSEOF'
{
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "taskapp.deploywithme.xyz",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [{"Value": "<INGRESS_LB_DNS>"}]
      }
    },
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "api.deploywithme.xyz",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [{"Value": "<INGRESS_LB_DNS>"}]
      }
    }
  ]
}
DNSEOF

aws route53 change-resource-record-sets \
  --hosted-zone-id <PARENT_ZONE_ID> \
  --change-batch file:///tmp/route53-taskapp.json

### Step 11: Apply Ingress Manifest

kubectl apply -f k8s/base/ingress.yaml

### Step 12: Install cert-manager

NOTE: Use v1.16.5 — newer versions are incompatible with Kubernetes 1.28.

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.5/cert-manager.yaml

Wait for cert-manager pods:
kubectl get pods -n cert-manager

### Step 13: Create ClusterIssuer

kubectl apply -f k8s/base/cert-manager/cluster-issuer.yaml

### Step 14: Verify TLS Certificate

kubectl get certificate -n taskapp

Expected output:
NAME          READY   SECRET        AGE
taskapp-tls   True    taskapp-tls   1m

If certificate shows errored, delete and re-trigger:
kubectl delete certificaterequest,order,challenge,certificate -n taskapp --all
kubectl annotate ingress taskapp-ingress -n taskapp cert-manager.io/cluster-issuer=letsencrypt-prod --overwrite

### Step 15: Verify All Endpoints

curl -I https://taskapp.deploywithme.xyz
curl https://api.deploywithme.xyz/api/health

Expected:
HTTP/2 200
{"database":"connected","status":"healthy"}

---

## 3. Scaling the Application

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

kubectl delete secret taskapp-secret -n taskapp

kubectl create secret generic taskapp-secret \
  --from-literal='SECRET_KEY=<new-secret-key>' \
  --from-literal='DATABASE_URL=postgresql://taskapp:<new-password>@postgres:5432/taskapp' \
  --from-literal='DATABASE_PASSWORD=<new-password>' \
  -n taskapp

kubectl rollout restart deployment/backend -n taskapp
kubectl rollout status deployment/backend -n taskapp

---

## 5. Zero-Downtime Deployment

kubectl set image deployment/frontend frontend=kelvintossyne/taskapp-frontend:new-tag -n taskapp
kubectl set image deployment/backend backend=kelvintossyne/taskapp-backend:new-tag -n taskapp

Monitor rollout:
kubectl rollout status deployment/frontend -n taskapp
kubectl rollout status deployment/backend -n taskapp

Rollback if needed:
kubectl rollout undo deployment/frontend -n taskapp
kubectl rollout undo deployment/backend -n taskapp

---

## 6. Troubleshooting

### Cluster Not Validating

kops validate cluster --state=${KOPS_STATE_STORE}

Check EC2 instances are running:
aws ec2 describe-instances \
  --filters "Name=tag:KubernetesCluster,Values=k8s.deploywithme.xyz" \
  "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].{ID:InstanceId,State:State.Name}" \
  --output table

Check nodeup logs on a worker:
aws ec2 get-console-output --instance-id <INSTANCE_ID> --latest --output text | tail -50

KNOWN ISSUE: kops 1.28 does NOT support Ubuntu 24.04.
Always use Ubuntu 22.04 AMI. Symptom: nodeup logs show
"error determining OS distribution: unsupported distro: ubuntu-24.04"

### Backend Returns 503 / Password Auth Failed

Check backend env vars:
kubectl exec -n taskapp <backend-pod> -- env | grep -i 'DATABASE\|POSTGRES'

The backend requires DATABASE_PASSWORD as a separate environment variable.
Make sure taskapp-secret contains DATABASE_PASSWORD key.

Reset postgres user password if needed:
kubectl exec -n taskapp <postgres-pod> -- bash -c \
  'psql -U taskapp -d taskapp -c "ALTER USER taskapp WITH PASSWORD '\''<password>'\'';"'

### TLS Certificate Not Issuing

kubectl describe certificate taskapp-tls -n taskapp
kubectl describe order -n taskapp
kubectl logs -n cert-manager deployment/cert-manager

Force re-issue:
kubectl delete certificaterequest,order,challenge,certificate -n taskapp --all
kubectl annotate ingress taskapp-ingress -n taskapp \
  cert-manager.io/cluster-issuer=letsencrypt-prod --overwrite

### DNS Not Resolving

dig taskapp.deploywithme.xyz @8.8.8.8
dig api.deploywithme.xyz @8.8.8.8

---

## 7. Destroying the Infrastructure

### Step 1: Delete the Kubernetes Cluster

kops delete cluster k8s.deploywithme.xyz \
  --state=s3://novara-kops-state-production --yes

### Step 2: Empty the Kops S3 Bucket

aws s3 rm s3://novara-kops-state-production --recursive

aws s3api delete-objects \
  --bucket novara-kops-state-production \
  --delete "$(aws s3api list-object-versions \
    --bucket novara-kops-state-production \
    --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' \
    --output json)"

### Step 3: Clear Route53 Non-Default Records

Remove CNAME and subdomain NS records from the hosted zone before destroying.

### Step 4: Destroy Terraform Infrastructure

cd terraform
terraform destroy

---

## 8. Health Checks

kops validate cluster
kubectl get nodes
kubectl get pods -n taskapp
kubectl get pvc -n taskapp
kubectl get certificate -n taskapp
curl https://api.deploywithme.xyz/api/health
curl -I https://taskapp.deploywithme.xyz
