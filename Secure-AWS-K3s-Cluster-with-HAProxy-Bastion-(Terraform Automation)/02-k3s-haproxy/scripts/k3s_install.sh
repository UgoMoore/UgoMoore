#!/bin/bash
sudo apt-get update -y
sudo apt-get install -y curl

# Install K3s
curl -sfL https://get.k3s.io | sh -

# Wait for startup
sleep 30

# Metrics Server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# KubeAudit
curl -s https://raw.githubusercontent.com/Shopify/kubeaudit/master/install | bash

echo "✅ K3s installed with Metrics Server and KubeAudit"
