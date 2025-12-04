output "haproxy_public_ip" {
  description = "Public IP of HAProxy Bastion"
  value       = aws_instance.haproxy_bastion.public_ip
}

output "k3s_private_ip" {
  description = "Private IP of K3s server node"
  value       = aws_instance.k3s_instance.private_ip
}
