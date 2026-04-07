# Runbook - TaskApp Operations

## Prerequisites
- AWS CLI configured
- kubectl installed
- kops installed
- Terraform >= 1.5.0
- A registered domain name

---

## 1. Initial Deployment

### Step 1 - Set environment variables
```bash
export AWS_REGION=us-east-1
export KOPS_STATE_STORE=s3://novara-kops-state-production
export CLUSTER_NAME=taskapp.k8s.local
```

### Step 2 - Deploy AWS infrastructure
```bash
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
cd ..
```

### Step 3 - Create Kubernetes cluster
```bash
kops create -f kops/cluster.yaml
kops update cluster $CLUSTER_NAME --yes
kops validate cluster $CLUSTER_NAME --wait 15m
```

### Step 4 - Install cert-manager
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
kubectl apply -f k8s/base/cert-manager/cluster-issuer.yaml
kubectl apply -f k8s/base/cert-manager/storage-class.yaml
```

### Step 5 - Deploy application
```bash
kubectl apply -k k8s/overlays/production/
kubectl get pods -w
```

---

## 2. Scaling the Cluster

### Scale worker nodes
```bash
kops edit ig nodes --name $CLUSTER_NAME
# Change minSize and maxSize
kops update cluster $CLUSTER_NAME --yes
kops rolling-update cluster $CLUSTER_NAME --yes
```

### Scale application pods
```bash
kubectl scale deployment frontend --replicas=3
kubectl scale deployment backend --replicas=3
```

---

## 3. Rotating Secrets

### Step 1 - Generate new encoded value
```bash
echo -n 'newpassword' | base64
```

### Step 2 - Update the secret
```bash
kubectl edit secret taskapp-secret
# Replace the base64 value
```

### Step 3 - Restart affected pods
```bash
kubectl rollout restart deployment/backend
kubectl rollout restart deployment/postgres
```

---

## 4. Troubleshooting Common Failures

### Pods not starting
```bash
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Database connection issues
```bash
kubectl exec -it <backend-pod> -- env | grep POSTGRES
kubectl exec -it <postgres-pod> -- psql -U taskapp_user -d taskapp
```

### SSL certificate not issuing
```bash
kubectl get certificate
kubectl describe certificate taskapp-tls
kubectl get clusterissuer
```

### Cluster node failure
```bash
kops validate cluster
kubectl get nodes
kops rolling-update cluster --yes
```

### etcd backup verification
```bash
aws s3 ls s3://novara-etcd-backups-production/taskapp.k8s.local/
```

---

## 5. Destroying the Cluster
```bash
# Delete application
kubectl delete -k k8s/overlays/production/

# Delete cluster
kops delete cluster $CLUSTER_NAME --yes

# Destroy infrastructure
cd terraform
terraform destroy -auto-approve
```
