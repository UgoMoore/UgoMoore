terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.14"  # stable v5 release
    }
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
}

#######################
# Call VPC Module
#######################
module "vpc" {
  source = "./01-vpc"

  vpc_name             = var.vpc_name
  vpc_cidr_block       = var.vpc_cidr_block
  public_subnet_cidr   = var.public_subnet_cidr
  private_subnet_cidr  = var.private_subnet_cidr
  availability_zone    = var.availability_zone
}

#######################
# Call HAProxy + K3s Module
#######################
module "k3s_haproxy" {
  source = "./02-k3s-haproxy"

  vpc_id             = module.vpc.vpc_id
  public_subnet_id   = module.vpc.public_subnet_id
  private_subnet_id  = module.vpc.private_subnet_id
  public_subnet_cidr = var.public_subnet_cidr
  nat_gateway_id     = module.vpc.nat_gateway_id

  ami_id               = var.ami_id
  haproxy_instance_type = var.haproxy_instance_type
  k3s_instance_type    = var.k3s_instance_type
  key_name             = var.key_name
  ssh_private_key_path = var.ssh_private_key_path
}

#######################
# Outputs
#######################
output "haproxy_public_ip" {
  value = module.k3s_haproxy.haproxy_public_ip
}

output "k3s_private_ip" {
  value = module.k3s_haproxy.k3s_private_ip
}

