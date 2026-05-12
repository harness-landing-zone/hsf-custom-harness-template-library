#!/bin/bash
# Setup script for running Harness Terraform

set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BOLD}Harness Terraform Setup${NC}\n"

# Check if tofu or terraform is installed
echo -n "Checking for OpenTofu/Terraform... "
if command -v tofu &> /dev/null; then
    TF_CMD="tofu"
    echo -e "${GREEN}✓${NC} OpenTofu found"
elif command -v terraform &> /dev/null; then
    TF_CMD="terraform"
    echo -e "${GREEN}✓${NC} Terraform found"
else
    echo -e "${RED}✗${NC} Not found"
    echo ""
    echo "Installing OpenTofu..."
    if command -v brew &> /dev/null; then
        brew install opentofu
        TF_CMD="tofu"
        echo -e "${GREEN}✓${NC} OpenTofu installed"
    else
        echo -e "${RED}Error:${NC} Homebrew not found. Install from https://brew.sh"
        exit 1
    fi
fi

# Prompt for Harness credentials if not set
if [ -z "$HARNESS_PLATFORM_API_KEY" ]; then
    echo ""
    echo -e "${YELLOW}HARNESS_PLATFORM_API_KEY not set${NC}"
    echo "Get your API key from: https://app.harness.io/ng/account/<your-account>/settings/resources/apikeys"
    read -p "Enter your Harness API Key: " api_key
    export HARNESS_PLATFORM_API_KEY="$api_key"
fi

if [ -z "$HARNESS_ACCOUNT_ID" ]; then
    echo ""
    echo -e "${YELLOW}HARNESS_ACCOUNT_ID not set${NC}"
    read -p "Enter your Harness Account ID: " account_id
    export HARNESS_ACCOUNT_ID="$account_id"
fi

# Choose deployment type
echo ""
echo "What do you want to deploy?"
echo "  1) Account setup (harness-platform-setup) - Run this first"
echo "  2) Organization (harness-organization) - Run after account setup"
echo "  3) Single project (harness-project) - Rarely used"
read -p "Choice (1-3): " choice

case $choice in
    1)
        DIR="harness-platform-setup"
        echo ""
        echo "Deploying account-level setup..."
        ;;
    2)
        DIR="harness-organization"
        echo ""
        read -p "Enter organization name (must match folder in platform-configs/organizations/): " org_name
        ORG_NAME="$org_name"
        echo "Deploying organization: $org_name"
        ;;
    3)
        DIR="harness-project"
        echo ""
        read -p "Enter organization ID: " org_id
        read -p "Enter project name: " proj_name
        ORG_ID="$org_id"
        PROJECT_NAME="$proj_name"
        echo "Deploying project: $proj_name"
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

cd "$DIR"

# Create terraform.tfvars if it doesn't exist
if [ ! -f terraform.tfvars ]; then
    echo ""
    echo "Creating terraform.tfvars..."
    cat > terraform.tfvars <<EOF
harness_platform_account = "$HARNESS_ACCOUNT_ID"
EOF

    if [ "$choice" == "2" ]; then
        echo "organization_name = \"$ORG_NAME\"" >> terraform.tfvars
    fi

    if [ "$choice" == "3" ]; then
        cat >> terraform.tfvars <<EOF
organization_id = "$ORG_ID"
project_name = "$PROJECT_NAME"
EOF
    fi

    cat >> terraform.tfvars <<EOF
tags = {
  managed_by = "terraform"
}
EOF
    echo -e "${GREEN}✓${NC} terraform.tfvars created"
fi

# Copy providers.tf if it doesn't exist
if [ ! -f providers.tf ] && [ -f ../providers.tf.example ]; then
    cp ../providers.tf.example providers.tf
    echo -e "${GREEN}✓${NC} providers.tf created"
fi

# Initialize
echo ""
echo "Initializing Terraform..."
$TF_CMD init

# Plan
echo ""
echo "Running plan (review changes before applying)..."
$TF_CMD plan -out=tfplan

echo ""
echo -e "${GREEN}${BOLD}Setup complete!${NC}"
echo ""
echo "Review the plan above. To apply changes, run:"
echo -e "  ${BOLD}cd $DIR && $TF_CMD apply tfplan${NC}"
echo ""
echo "Or to see the plan again:"
echo -e "  ${BOLD}cd $DIR && $TF_CMD show tfplan${NC}"
