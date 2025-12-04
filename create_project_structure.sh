#!/bin/bash

# Create root folder
mkdir -p Amazing-Heights-K3s-AWS-Cluster
cd Amazing-Heights-K3s-AWS-Cluster

echo "📁 Creating project folders..."

# Backend configuration
mkdir -p backend/

# Modules
mkdir -p modules/vpc
mkdir -p modules/security
mkdir -p modules/k3s-server
mkdir -p modules/network

# Scripts
mkdir -p scripts

# Root Terraform files
touch main.tf
touch variables.tf
touch outputs.tf
touch provider.tf

# Placeholder files inside modules
echo "# VPC Module" > modules/vpc/main.tf
echo "# Security Module" > modules/security/main.tf
echo "# K3s Server Module" > modules/k3s-server/main.tf
echo "# Network Module" > modules/network/main.tf

# Scripting placeholder
echo "# Automation scripts go here" > scripts/README.md

# Backend placeholder
echo "# Backend configuration for Terraform remote state" > backend/backend.tf

echo "✅ Project structure created successfully!"
