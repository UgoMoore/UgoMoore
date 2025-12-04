#!/bin/bash

# ============================================
# GitHub Portfolio Automation Script
# ============================================
# - Pushes all sub-projects to GitHub
# - Updates main portfolio README.md automatically
# ============================================

BASE_DIR=~/Documents/GitHub-Portfolio
MAIN_REPO_DIR="$BASE_DIR/UgoMoore"
MAIN_README="$MAIN_REPO_DIR/README.md"

declare -A REPOS
REPOS["K3S-secure-cluster-AWS-Terraform"]="https://github.com/UgoMoore/K3S-secure-cluster-AWS-Terraform.git"
REPOS["Heliostech-AWS-EKS-production"]="https://github.com/UgoMoore/Heliostech-AWS-EKS-production.git"
REPOS["Vulnerability-Management-labs"]="https://github.com/UgoMoore/Vulnerability-Management-labs.git"
REPOS["GRC-labs"]="https://github.com/UgoMoore/GRC-labs.git"
REPOS["Google-Cybersecurity-labs"]="https://github.com/UgoMoore/Google-Cybersecurity-labs.git"
REPOS["Python-automation-labs"]="https://github.com/UgoMoore/Python-automation-labs.git"

# Start updating main README
echo "Updating main portfolio README.md ..."
echo "" >> "$MAIN_README"
echo "## 🚀 My Cybersecurity & Cloud Projects" >> "$MAIN_README"
echo "" >> "$MAIN_README"

# Process each sub-project
for FOLDER in "${!REPOS[@]}"; do
  echo "--------------------------------------------"
  echo "Processing: $FOLDER"
  echo "--------------------------------------------"
  
  cd "$BASE_DIR/$FOLDER" || { echo "❌ Folder not found: $FOLDER"; continue; }

  # Initialize Git if missing
  if [ ! -d ".git" ]; then
    git init
  fi

  git remote remove origin 2>/dev/null
  git remote add origin "${REPOS[$FOLDER]}"

  git branch -M main

  # Pull any remote README
  git pull origin main --allow-unrelated-histories 2>/dev/null

  git add .
  git commit -m "Update project files" 2>/dev/null

  # Push to GitHub
  git push -u origin main --force

  echo "✔ Successfully pushed: $FOLDER"

  # Add link to main README
  echo "- **${FOLDER}** → [View Repository](${REPOS[$FOLDER]})" >> "$MAIN_README"
done

echo ""
echo "--------------------------------------------"
echo "Pushing updated main portfolio README..."
echo "--------------------------------------------"

cd "$MAIN_REPO_DIR"

git add README.md
git commit -m "Auto-update project links"
git push origin main

echo ""
echo "======================================"
echo "✅ All projects processed and portfolio updated!"
echo "======================================"
