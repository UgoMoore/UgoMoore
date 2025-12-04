#!/bin/bash

# ================================
#  CONFIGURATION
# ================================
PORTFOLIO_DIR="$(pwd)"
MAIN_README="$PORTFOLIO_DIR/README.md"

REPOS=(
  "K3S-secure-cluster-AWS-Terraform"
  "Heliostech-AWS-EKS-production"
  "Vulnerability-Management-labs"
  "GRC-labs"
  "Google-Cybersecurity-labs"
  "Python-automation-labs"
)

GITHUB_USER="UgoMoore"

# ================================
#  COLOR CODES
# ================================
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m" # No color

# ================================
#  FUNCTION: PROCESS SUB-REPO
# ================================
process_repo() {
    local repo=$1
    echo -e "${BLUE}--------------------------------------${NC}"
    echo -e "${BLUE}Processing: $repo${NC}"
    echo -e "${BLUE}--------------------------------------${NC}"

    cd "$PORTFOLIO_DIR/$repo" || {
        echo -e "${RED}❌ ERROR: Folder '$repo' does not exist.${NC}"
        return
    }

    # Initialize Git if missing
    if [ ! -d ".git" ]; then
        echo -e "${YELLOW}Initializing Git for $repo...${NC}"
        git init
        git branch -M main
        git remote add origin "https://github.com/$GITHUB_USER/$repo.git"
    fi

    # Fetch remote (in case repo exists)
    git fetch origin main --quiet 2>/dev/null

    # Merge remote content safely (avoid stopping script)
    git merge origin/main --allow-unrelated-histories -m "Auto-merge remote content" --quiet 2>/dev/null

    # Add & commit changes
    git add .
    git commit -m "Auto-sync updates" --quiet 2>/dev/null

    # Push repo
    git push -u origin main 2>/dev/null

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✔ $repo successfully pushed to GitHub!${NC}"
    else
        echo -e "${RED}❌ Failed to push $repo. Check GitHub repo exists.${NC}"
    fi

    cd "$PORTFOLIO_DIR"
}

# ================================
# UPDATE MAIN PORTFOLIO README
# ================================
update_main_readme() {
    echo -e "${YELLOW}Updating main README.md...${NC}"

    echo "# Ugo Moore – Cloud Security & DevOps Portfolio" > "$MAIN_README"
    echo "" >> "$MAIN_README"
    echo "Welcome to my Cloud Security, DevOps, and Automation Portfolio.  
This repository links to all my hands-on labs and real-world projects." >> "$MAIN_README"
    echo "" >> "$MAIN_README"
    echo "## 🔗 Project Index" >> "$MAIN_README"
    echo "" >> "$MAIN_README"

    for repo in "${REPOS[@]}"; do
        echo "- [${repo}](https://github.com/${GITHUB_USER}/${repo})" >> "$MAIN_README"
    done

    echo "" >> "$MAIN_README"
    echo "Updated automatically on: **$(date)**" >> "$MAIN_README"

    echo -e "${GREEN}✔ README.md updated successfully!${NC}"
}

# ================================
# MAIN EXECUTION
# ================================
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}🚀 Starting Portfolio Auto-Sync Script${NC}"
echo -e "${BLUE}======================================${NC}"

for repo in "${REPOS[@]}"; do
    process_repo "$repo"
done

update_main_readme

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}✔ All portfolio sub-projects processed.${NC}"
echo -e "${GREEN}======================================${NC}"
