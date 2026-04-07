#!/bin/bash
set -e

echo "=== Sealing Secrets ==="

# Check kubeseal is installed
if ! command -v kubeseal &> /dev/null; then
  echo "Installing kubeseal..."
  wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/kubeseal-0.24.0-linux-amd64.tar.gz
  tar -xvzf kubeseal-0.24.0-linux-amd64.tar.gz kubeseal
  sudo install -m 755 kubeseal /usr/local/bin/kubeseal
  rm kubeseal-0.24.0-linux-amd64.tar.gz
fi

echo ">>> Sealing secret..."
kubeseal \
  --controller-name=sealed-secrets \
  --controller-namespace=sealed-secrets \
  --format yaml \
  < k8s/base/secret.yaml \
  > k8s/base/sealed-secrets/sealed-secret.yaml

echo ">>> Sealed secret created at k8s/base/sealed-secrets/sealed-secret.yaml"
echo ">>> You can now safely commit sealed-secret.yaml to Git"
echo ">>> Never commit k8s/base/secret.yaml to Git"
