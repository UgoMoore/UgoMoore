variable "access_key" {}
variable "secret_key" {}
variable "aws_region" {
  default = "us-east-1"
}

variable "vpc_name" {}
variable "vpc_cidr_block" {}
variable "public_subnet_cidr" {}
variable "private_subnet_cidr" {}
variable "availability_zone" {
  default = "us-east-1a"
}

variable "ami_id" {
  default = "ami-020cba7c55df1f615"
}
variable "haproxy_instance_type" {
  default = "t3.micro"
}
variable "k3s_instance_type" {
  default = "t3.small"
}
variable "key_name" {}
variable "ssh_private_key_path" {}
