variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_id" {
  description = "Public Subnet ID"
  type        = string
}

variable "private_subnet_id" {
  description = "Private Subnet ID"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block of public subnet"
  type        = string
}

variable "nat_gateway_id" {
  description = "NAT Gateway ID"
  type        = string
}

variable "ami_id" {
  description = "Ubuntu 24.04 AMI"
  type        = string
}

variable "haproxy_instance_type" {
  description = "Instance type for HAProxy"
  type        = string
  default     = "t3.micro"
}

variable "k3s_instance_type" {
  description = "Instance type for K3s"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key"
  type        = string
}
