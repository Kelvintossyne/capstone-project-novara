#!/bin/bash
set -e

echo "=== Taskapp Destroy ==="

CLUSTER_NAME="taskapp.k8s.local"
KOPS_STATE_STORE="s3://novara-kops-state-production"

echo ">>> Deleting Kubernetes resources..."
kubectl delete -f k8s/

echo ">>> Destroying kops cluster..."
export KOPS_STATE_STORE=$KOPS_STATE_STORE
kops delete cluster $CLUSTER_NAME --yes

echo ">>> Destroying Terraform infrastructure..."
cd terraform
terraform destroy -auto-approve
cd ..

echo "=== Destroy complete ==="
