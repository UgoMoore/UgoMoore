# 02-k3s-haproxy/main.tf (UPDATED)
# This file defines HAProxy (bastion) + single K3s server deployment.
# Key fixes applied:
#  - K3s security group now allows SSH and API (6443) only from the HAProxy security group
#  - Removed invalid depends_on referencing variables
#  - Kept HAProxy SG open for public SSH and 6443 (for API forwarding)

#########################
# Security Group: HAProxy
#########################
resource "aws_security_group" "haproxy_sg" {
  name        = "haproxy_sg"
  description = "Allow public access to HAProxy"
  vpc_id      = var.vpc_id

  # Allow API (TCP 6443) from anywhere (HAProxy will forward to K3s)
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH from anywhere to bastion (you may lock this to your IP later)
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

  tags = { Name = "haproxy_sg" }
}

#########################
# Security Group: K3s Node
#########################
resource "aws_security_group" "k3s_sg" {
  name        = "k3s_sg"
  description = "Allow SSH & K3s API traffic from HAProxy only"
  vpc_id      = var.vpc_id

  # Allow SSH only from the HAProxy security group
  ingress {
    description     = "SSH from HAProxy"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.haproxy_sg.id]
  }

  # Allow K3s API (6443) only from HAProxy
  ingress {
    description     = "K3s API from HAProxy"
    from_port       = 6443
    to_port         = 6443
    protocol        = "tcp"
    security_groups = [aws_security_group.haproxy_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "k3s_sg" }
}

#########################
# HAProxy EC2 (Public)
#########################
resource "aws_instance" "haproxy_bastion" {
  ami                         = var.ami_id
  instance_type               = var.haproxy_instance_type
  subnet_id                   = var.public_subnet_id
  associate_public_ip_address = true
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.haproxy_sg.id]

  user_data = <<-EOT
              #!/bin/bash
              apt update -y && apt install -y haproxy
              cat <<EOF > /etc/haproxy/haproxy.cfg
              global
                log /dev/log local0
                maxconn 2048
              defaults
                mode tcp
                timeout connect 5s
                timeout client 30s
                timeout server 30s
              frontend k8s_api
                bind *:6443
                default_backend k8s_backend
              backend k8s_backend
                server k3s_node ${aws_instance.k3s_instance.private_ip}:6443 check
              EOF
              systemctl restart haproxy
              EOT

  tags = { Name = "HAProxy Bastion" }
}

#########################
# K3s EC2 (Private)
#########################
resource "aws_instance" "k3s_instance" {
  ami                         = var.ami_id
  instance_type               = var.k3s_instance_type
  subnet_id                   = var.private_subnet_id
  associate_public_ip_address = false
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.k3s_sg.id]

  user_data = file("${path.module}/scripts/k3s_install.sh")

  tags = { Name = "K3s Server Node" }

  # removed invalid depends_on referencing variables/resources not in this module
}

#########################
# Pull Kubeconfig (local-exec)
#########################
resource "null_resource" "export_kubeconfig" {
  depends_on = [aws_instance.k3s_instance, aws_instance.haproxy_bastion]

  provisioner "local-exec" {
    command = "bash ${path.module}/scripts/kubeconfig_export.sh"
    environment = {
      BASTION_IP  = aws_instance.haproxy_bastion.public_ip
      PRIVATE_IP  = aws_instance.k3s_instance.private_ip
      SSH_KEY     = var.ssh_private_key_path
    }
  }
}
