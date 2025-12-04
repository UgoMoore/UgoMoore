#!/bin/bash
set -e

BUCKET="amazing-heights-terraform-state"   # use existing bucket
REGION="us-east-1"

echo "🚀 Using existing backend bucket $BUCKET in $REGION"

echo "🔒 Enabling versioning..."
aws s3api put-bucket-versioning \
  --bucket $BUCKET \
  --versioning-configuration Status=Enabled || true

echo "✨ Writing backend.tf ..."
cat <<EOF > backend.tf
terraform {
  backend "s3" {
    bucket       = "$BUCKET"
    key          = "k3s-cluster/terraform.tfstate"
    region       = "$REGION"
    encrypt      = true
    use_lockfile = true
  }
}
EOF

echo "🎉 Backend setup complete — now run:"
echo "👉 terraform init -reconfigure"
