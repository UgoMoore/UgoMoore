terraform {
  backend "s3" {
    bucket       = "amazing-heights-terraform-state"
    key          = "k3s-cluster/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
