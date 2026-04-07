#!/bin/bash
set -e

echo "=== Taskapp Deploy ==="

# Variables
CLUSTER_NAME="taskapp.k8s.local"
KOPS_STATE_STORE="s3://novara-kops-state-production"
AWS_REGION="us-east-1"

echo ">>> Initializing Terraform..."
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
cd ..

echo ">>> Creating kops cluster..."
export KOPS_STATE_STORE=$KOPS_STATE_STORE
kops create -f kops/cluster.yaml
kops update cluster $CLUSTER_NAME --yes
kops validate cluster $CLUSTER_NAME --wait 10m

echo ">>> Deploying Kubernetes manifests..."
kubectl apply -f k8s/

echo ">>> Checking pods..."
kubectl get pods

echo "=== Deploy complete ==="
