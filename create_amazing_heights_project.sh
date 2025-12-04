#!/bin/bash
set -e

PROJECT_NAME="Amazing-Heights-K3s-AWS-Cluster"
echo "🚀 Creating project folder: $PROJECT_NAME"

mkdir -p $PROJECT_NAME/{01-vpc,02-bastion,03-k3s/scripts,04-addons,kubeconfig}

echo "✅ Folder structure created."

# -------------------------
# Root terraform.tfvars
# -------------------------
cat > $PROJECT_NAME/terraform.tfvars <<EOL
access_key  = "YOUR_AWS_ACCESS_KEY"
secret_key  = "YOUR_AWS_SECRET_KEY"
aws_region  = "us-east-1"
key_name    = "my-aws-key"
ami_id      = "ami-020cba7c55df1f615"

vpc_name            = "amazing-heights-vpc"
vpc_cidr_block      = "10.0.0.0/16"
public_subnet_cidr  = "10.0.1.0/24"
private_subnet_cidr = "10.0.2.0/24"

k3s_instance_type   = "t2.medium"
bastion_instance_type = "t2.micro"
EOL

# -------------------------
# Root variables.tf
# -------------------------
cat > $PROJECT_NAME/variables.tf <<EOL
variable "access_key" { type = string }
variable "secret_key" { type = string }
variable "aws_region" { type = string, default = "us-east-1" }
variable "key_name" { type = string }
variable "ami_id" { type = string }
variable "k3s_instance_type" { type = string, default = "t2.medium" }
variable "bastion_instance_type" { type = string, default = "t2.micro" }
variable "vpc_name" { type = string }
variable "vpc_cidr_block" { type = string }
variable "public_subnet_cidr" { type = string }
variable "private_subnet_cidr" { type = string }
EOL

# -------------------------
# Root main.tf
# -------------------------
cat > $PROJECT_NAME/main.tf <<'EOL'
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = { source = "hashicorp/aws" }
    helm = { source = "hashicorp/helm" }
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
}

module "vpc" {
  source = "./01-vpc"

  aws_region          = var.aws_region
  vpc_name            = var.vpc_name
  vpc_cidr_block      = var.vpc_cidr_block
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
}

module "bastion" {
  source           = "./02-bastion"
  aws_region       = var.aws_region
  public_subnet_id = module.vpc.public_subnet_id
  key_name         = var.key_name
  ami_id           = var.ami_id
}

module "k3s" {
  source            = "./03-k3s"
  aws_region        = var.aws_region
  private_subnet_id = module.vpc.private_subnet_id
  key_name          = var.key_name
  bastion_ip        = module.bastion.bastion_public_ip
  k3s_instance_type = var.k3s_instance_type
  ami_id            = var.ami_id
}

module "addons" {
  source          = "./04-addons"
  kubeconfig_path = "./kubeconfig/amazing_heights.yaml"
}
EOL

# -------------------------
# Module 01-vpc
# -------------------------
cat > $PROJECT_NAME/01-vpc/main.tf <<EOL
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = var.vpc_name }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone = var.aws_region
  tags = { Name = "public_subnet" }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.aws_region
  tags = { Name = "private_subnet" }
}

output "public_subnet_id" { value = aws_subnet.public.id }
output "private_subnet_id" { value = aws_subnet.private.id }
output "vpc_id" { value = aws_vpc.main.id }
EOL

cat > $PROJECT_NAME/01-vpc/variables.tf <<EOL
variable "aws_region" { type = string }
variable "vpc_name" { type = string }
variable "vpc_cidr_block" { type = string }
variable "public_subnet_cidr" { type = string }
variable "private_subnet_cidr" { type = string }
EOL

# -------------------------
# Module 02-bastion
# -------------------------
cat > $PROJECT_NAME/02-bastion/main.tf <<EOL
resource "aws_security_group" "bastion_sg" {
  name   = "bastion_sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "bastion" {
  ami                         = var.ami_id
  instance_type               = var.bastion_instance_type
  subnet_id                   = var.public_subnet_id
  key_name                    = var.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]

  tags = { Name = "Bastion Host" }
}

output "bastion_public_ip" { value = aws_instance.bastion.public_ip }
EOL

cat > $PROJECT_NAME/02-bastion/variables.tf <<EOL
variable "aws_region" { type = string }
variable "public_subnet_id" { type = string }
variable "key_name" { type = string }
variable "ami_id" { type = string }
variable "bastion_instance_type" { type = string }
variable "vpc_id" { type = string }
EOL

# -------------------------
# Module 03-k3s
# -------------------------
cat > $PROJECT_NAME/03-k3s/main.tf <<EOL
resource "aws_security_group" "k3s_sg" {
  name   = "k3s_sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.public_subnet_cidr]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.public_subnet_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "k3s" {
  ami                         = var.ami_id
  instance_type               = var.k3s_instance_type
  subnet_id                   = var.private_subnet_id
  associate_public_ip_address = false
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.k3s_sg.id]

  user_data = file("${path.module}/scripts/k3s_install.sh")

  tags = { Name = "K3s Node" }
}

output "k3s_private_ip" { value = aws_instance.k3s.private_ip }
EOL

cat > $PROJECT_NAME/03-k3s/variables.tf <<EOL
variable "private_subnet_id" { type = string }
variable "key_name" { type = string }
variable "ami_id" { type = string }
variable "k3s_instance_type" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_cidr" { type = string }
EOL

cat > $PROJECT_NAME/03-k3s/scripts/k3s_install.sh <<'EOL'
#!/bin/bash
curl -sfL https://get.k3s.io | sh -
sleep 20
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
echo "✅ K3s installed with Metrics Server"
EOL

# -------------------------
# Module 04-addons
# -------------------------
cat > $PROJECT_NAME/04-addons/main.tf <<EOL
provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"

  values = [
    <<-EOT
    args:
      - --kubelet-insecure-tls
    EOT
  ]
}
EOL

cat > $PROJECT_NAME/04-addons/variables.tf <<EOL
variable "kubeconfig_path" { type = string }
EOL

echo "✅ Amazing-Heights-K3s-AWS-Cluster skeleton is ready!"
echo "Next: cd $PROJECT_NAME, then run 'terraform init' and 'terraform apply -auto-approve'"
