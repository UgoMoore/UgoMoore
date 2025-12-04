#!/bin/bash
set -e

PROJECT_NAME="Amazing-Heights-K3s-AWS-Cluster"

echo "📁 Creating project folder structure and starter files for $PROJECT_NAME..."

# Create folders
mkdir -p $PROJECT_NAME/{modules/01-vpc,modules/02-bastion,modules/03-k3s,modules/04-addons,scripts}

# ------------------------------
# Root files
# ------------------------------
# README.md
cat > $PROJECT_NAME/README.md <<EOL
# Amazing-Heights-K3s-AWS-Cluster

A secure, single-node K3s Kubernetes cluster deployed on AWS using Terraform and HAProxy.
EOL

# .gitignore
cat > $PROJECT_NAME/.gitignore <<EOL
# Kubeconfig
kubeconfig.yaml

# SSH keys
*.pem

# Terraform files
*.tfstate
*.tfstate.backup
*.tfvars
.terraform/

# Logs
*.log
*.sh~

# Editor metadata
.vscode/
.idea/
.DS_Store
EOL

# terraform.tfvars
cat > $PROJECT_NAME/terraform.tfvars <<EOL
access_key  = "YOUR_AWS_ACCESS_KEY"
secret_key  = "YOUR_AWS_SECRET_KEY"
aws_region  = "us-east-1"

key_name    = "my-aws-key"
ssh_private_key_path = "./my-aws-key.pem"

vpc_name                = "amazing-heights-vpc"
vpc_cidr_block          = "10.0.0.0/16"
public_subnet_cidr      = "10.0.1.0/24"
private_subnet_1_cidr   = "10.0.2.0/24"
private_subnet_2_cidr   = "10.0.3.0/24"
availability_zone       = "us-east-1a"

ami_id                 = "ami-020cba7c55df1f615"
k3s_instance_type      = "t2.medium"
haproxy_instance_type  = "t2.micro"
k3s_disk_size          = 20
EOL

# backend.tf
cat > $PROJECT_NAME/backend.tf <<EOL
terraform {
  backend "s3" {
    bucket = "YOUR_TERRAFORM_STATE_BUCKET"
    key    = "amazing-heights-k3s/terraform.tfstate"
    region = "us-east-1"
  }
}
EOL

# main.tf
cat > $PROJECT_NAME/main.tf <<EOL
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.21.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.9.0"
    }
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
}

provider "helm" {
  kubernetes {
    config_path = "./kubeconfig/amazing_heights.yaml"
  }
}

# Modules
module "vpc" {
  source = "./modules/01-vpc"
}

module "bastion" {
  source = "./modules/02-bastion"
}

module "k3s" {
  source = "./modules/03-k3s"
}

module "addons" {
  source          = "./modules/04-addons"
  kubeconfig_path = "./kubeconfig/amazing_heights.yaml"
  providers       = { helm = helm }
}
EOL

# variables.tf
cat > $PROJECT_NAME/variables.tf <<EOL
variable "access_key" { type = string }
variable "secret_key" { type = string }
variable "aws_region" { type = string }

variable "key_name" { type = string }
variable "ssh_private_key_path" { type = string }

variable "vpc_name" { type = string }
variable "vpc_cidr_block" { type = string }
variable "public_subnet_cidr" { type = string }
variable "private_subnet_1_cidr" { type = string }
variable "private_subnet_2_cidr" { type = string }
variable "availability_zone" { type = string }

variable "ami_id" { type = string }
variable "haproxy_instance_type" { type = string }
variable "k3s_instance_type" { type = string }
variable "k3s_disk_size" { type = number }
EOL

# outputs.tf
cat > $PROJECT_NAME/outputs.tf <<EOL
output "haproxy_public_ip" { value = module.bastion.public_ip }
output "k3s_private_ip" { value = module.k3s.private_ip }
EOL

# ------------------------------
# Scripts
# ------------------------------
# k3s_install.sh
cat > $PROJECT_NAME/scripts/k3s_install.sh <<EOL
#!/bin/bash
sudo apt-get update -y
sudo apt-get install -y curl
curl -sfL https://get.k3s.io | sh -
sleep 30
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
curl -s https://raw.githubusercontent.com/Shopify/kubeaudit/master/install | bash
echo "✅ K3s installed with Metrics Server and KubeAudit"
EOL

# kubeconfig_export.sh
cat > $PROJECT_NAME/scripts/kubeconfig_export.sh <<EOL
#!/bin/bash
set -e
REMOTE_USER=ubuntu
K3S_PRIVATE_IP=\$(terraform output -raw k3s_private_ip)
HAPROXY_PUBLIC_IP=\$(terraform output -raw haproxy_public_ip)
SSH_KEY="./new-keys.pem"
REMOTE_KUBECONFIG_PATH="/etc/rancher/k3s/k3s.yaml"
LOCAL_KUBECONFIG_PATH="./kubeconfig.yaml"

scp -o ProxyJump=\$REMOTE_USER@\$HAPROXY_PUBLIC_IP -i "\$SSH_KEY" "\$REMOTE_USER@\$K3S_PRIVATE_IP:\$REMOTE_KUBECONFIG_PATH" "\$LOCAL_KUBECONFIG_PATH"
sed -i "s/127.0.0.1/\$K3S_PRIVATE_IP/g" "\$LOCAL_KUBECONFIG_PATH"
echo "✅ kubeconfig.yaml ready. Run: export KUBECONFIG=\$(pwd)/kubeconfig.yaml"
EOL

# ------------------------------
# Modules placeholders
# ------------------------------
for MODULE in 01-vpc 02-bastion 03-k3s 04-addons; do
cat > $PROJECT_NAME/modules/$MODULE/main.tf <<EOL
# Placeholder main.tf for $MODULE
EOL
cat > $PROJECT_NAME/modules/$MODULE/variables.tf <<EOL
# Placeholder variables.tf for $MODULE
EOL
cat > $PROJECT_NAME/modules/$MODULE/outputs.tf <<EOL
# Placeholder outputs.tf for $MODULE
EOL
done

# ------------------------------
# GitHub auto-push script
# ------------------------------
cat > $PROJECT_NAME/setup_and_push_projects.sh <<'EOL'
#!/bin/bash
set -e
git init
git add .
git commit -m "Initial commit: Amazing-Heights-K3s-AWS-Cluster project"
# Replace YOUR_GITHUB_REPO_URL with your repo
git remote add origin YOUR_GITHUB_REPO_URL
git branch -M main
git push -u origin main
EOL

echo "✅ Project structure and starter files created successfully!"
echo "Next steps:"
echo "1️⃣ Update terraform.tfvars with your AWS credentials."
echo "2️⃣ Complete module Terraform code in modules/ folders."
echo "3️⃣ Run 'terraform init', 'terraform plan', and 'terraform apply'."
echo "4️⃣ Use setup_and_push_projects.sh to push to GitHub."
