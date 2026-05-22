# Remote Backend Setup for Multi-Org Management

## Problem

Each organization needs its own state file. With remote backends (TFE, S3, etc.), you need to:
1. Create separate state storage per org
2. Avoid state conflicts
3. Make it easy to manage multiple orgs

## Solution Options

### Option 1: Terraform Workspaces (Best for TFE)

#### Setup

Create `harness-organization/backend.tf`:

```hcl
terraform {
  backend "remote" {
    organization = "your-tfe-org-name"
    
    workspaces {
      prefix = "harness-org-"
    }
  }
}
```

#### Usage

```bash
cd harness-organization/

# First time setup
tofu login  # Login to TFE

# Deploy Example Org One
tofu workspace new harness-org-example-one
cat > terraform.tfvars <<EOF
harness_platform_account = "abc123"
organization_name = "Example Org One"
EOF
tofu init
tofu apply

# Deploy Example Org Two
tofu workspace new harness-org-example-two
cat > terraform.tfvars <<EOF
harness_platform_account = "abc123"
organization_name = "Example Org Two"
EOF
tofu apply

# List all org workspaces
tofu workspace list

# Switch between orgs
tofu workspace select harness-org-example-one
tofu plan

# Update specific org
tofu workspace select harness-org-example-two
tofu apply
```

#### Pros
- ✅ Single directory structure
- ✅ Easy to switch between orgs
- ✅ Native TFE feature
- ✅ Single backend.tf file

#### Cons
- ⚠️ Must remember to switch workspaces
- ⚠️ terraform.tfvars shared (easy to apply wrong config to wrong workspace)

---

### Option 2: Separate Directories (Best for CI/CD)

#### Setup

Create directory per org:

```bash
mkdir -p harness-orgs/{example-org-one,example-org-two}
```

**harness-orgs/example-org-one/main.tf:**
```hcl
module "harness_organization" {
  source = "../../harness-organization"
  
  harness_platform_account = var.harness_platform_account
  organization_name        = "Example Org One"
  tags                     = var.tags
}
```

**harness-orgs/example-org-one/backend.tf:**
```hcl
terraform {
  backend "remote" {
    organization = "your-tfe-org"
    
    workspaces {
      name = "harness-org-example-one"  # Unique workspace per org
    }
  }
}
```

**harness-orgs/example-org-one/variables.tf:**
```hcl
variable "harness_platform_account" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
```

**harness-orgs/example-org-one/terraform.tfvars:**
```hcl
harness_platform_account = "abc123"
tags = {
  managed_by = "terraform"
}
```

Repeat for `example-org-two/`.

#### Usage

```bash
# Deploy Org One
cd harness-orgs/example-org-one/
tofu init
tofu apply

# Deploy Org Two
cd ../example-org-two/
tofu init
tofu apply

# Update Org One
cd ../example-org-one/
tofu plan
tofu apply
```

#### Pros
- ✅ Each org completely isolated
- ✅ No workspace switching
- ✅ Each org has its own tfvars (no confusion)
- ✅ Great for CI/CD (one directory = one deployment)
- ✅ Easy to see what orgs exist (`ls harness-orgs/`)

#### Cons
- ⚠️ More directories to manage
- ⚠️ Need to keep module source path updated

---

### Option 3: S3 Backend with Key Prefix

#### Setup

**harness-organization/backend.tf:**
```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    region = "us-east-1"
    # Key provided at runtime
  }
}
```

#### Usage

```bash
cd harness-organization/

# Deploy Org One
tofu init -backend-config="key=harness/orgs/example-org-one/terraform.tfstate"
cat > terraform.tfvars <<EOF
organization_name = "Example Org One"
harness_platform_account = "abc123"
EOF
tofu apply

# Deploy Org Two (reinit with different key)
tofu init -reconfigure -backend-config="key=harness/orgs/example-org-two/terraform.tfstate"
cat > terraform.tfvars <<EOF
organization_name = "Example Org Two"
harness_platform_account = "abc123"
EOF
tofu apply
```

#### S3 State Structure
```
s3://my-terraform-state/
├── harness/
│   ├── account/terraform.tfstate          # Platform setup
│   └── orgs/
│       ├── example-org-one/terraform.tfstate
│       └── example-org-two/terraform.tfstate
```

#### Pros
- ✅ State keys clearly named
- ✅ Single directory
- ✅ Works with any S3-compatible backend

#### Cons
- ⚠️ Must remember to pass -backend-config each time
- ⚠️ Easy to forget and overwrite wrong state

---

## Recommended Approach by Use Case

### For Small Teams (1-5 orgs)
**Use Option 1: Workspaces**
- Simple to understand
- Easy to switch
- One place to work from

### For Large Teams / Production (5+ orgs)
**Use Option 2: Separate Directories**
- Clear isolation
- No mistakes switching workspaces
- Easy CI/CD integration
- Each org is a PR

### For Existing S3 Setup
**Use Option 3: S3 with Key Prefix**
- Works with your existing backend
- Clear state organization

---

## Complete Example: Option 2 Setup Script

```bash
#!/bin/bash
# setup-org-deployment.sh
# Creates isolated directory for a new org

ORG_NAME=$1
ORG_IDENTIFIER=$(echo "$ORG_NAME" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')

if [ -z "$ORG_NAME" ]; then
    echo "Usage: ./setup-org-deployment.sh \"Organization Name\""
    exit 1
fi

DEPLOY_DIR="harness-orgs/${ORG_IDENTIFIER}"
mkdir -p "$DEPLOY_DIR"

# Create main.tf
cat > "$DEPLOY_DIR/main.tf" <<EOF
module "harness_organization" {
  source = "../../harness-organization"
  
  harness_platform_account = var.harness_platform_account
  organization_name        = var.organization_name
  tags                     = var.tags
}
EOF

# Create variables.tf
cat > "$DEPLOY_DIR/variables.tf" <<EOF
variable "harness_platform_account" {
  type        = string
  description = "Harness Account ID"
}

variable "organization_name" {
  type        = string
  description = "Organization name"
  default     = "$ORG_NAME"
}

variable "tags" {
  type        = map(string)
  description = "Tags for resources"
  default     = {}
}
EOF

# Create terraform.tfvars
cat > "$DEPLOY_DIR/terraform.tfvars" <<EOF
harness_platform_account = "YOUR_ACCOUNT_ID"
organization_name        = "$ORG_NAME"
tags = {
  managed_by = "terraform"
  org        = "$ORG_IDENTIFIER"
}
EOF

# Create backend.tf
cat > "$DEPLOY_DIR/backend.tf" <<EOF
terraform {
  backend "remote" {
    organization = "your-tfe-org"
    
    workspaces {
      name = "harness-org-${ORG_IDENTIFIER}"
    }
  }
}
EOF

# Create outputs.tf
cat > "$DEPLOY_DIR/outputs.tf" <<EOF
output "organization_id" {
  value = module.harness_organization.organization_id
}

output "projects" {
  value = module.harness_organization.projects
}
EOF

echo "✅ Created deployment directory: $DEPLOY_DIR"
echo ""
echo "Next steps:"
echo "  1. cd $DEPLOY_DIR"
echo "  2. Edit terraform.tfvars with your account ID"
echo "  3. tofu init"
echo "  4. tofu apply"
```

Usage:
```bash
chmod +x setup-org-deployment.sh
./setup-org-deployment.sh "Example Org One"
cd harness-orgs/example-org-one/
# Edit terraform.tfvars
tofu init
tofu apply
```

---

## CI/CD Integration (GitHub Actions Example)

For Option 2 (separate directories):

```yaml
# .github/workflows/deploy-org.yml
name: Deploy Harness Organization

on:
  push:
    paths:
      - 'harness-orgs/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        org:
          - example-org-one
          - example-org-two
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: opentofu/setup-opentofu@v1
      
      - name: Terraform Init
        working-directory: harness-orgs/${{ matrix.org }}
        env:
          TF_TOKEN_app_terraform_io: ${{ secrets.TF_API_TOKEN }}
        run: tofu init
      
      - name: Terraform Plan
        working-directory: harness-orgs/${{ matrix.org }}
        env:
          TF_TOKEN_app_terraform_io: ${{ secrets.TF_API_TOKEN }}
          HARNESS_PLATFORM_API_KEY: ${{ secrets.HARNESS_API_KEY }}
        run: tofu plan
      
      - name: Terraform Apply
        if: github.ref == 'refs/heads/main'
        working-directory: harness-orgs/${{ matrix.org }}
        env:
          TF_TOKEN_app_terraform_io: ${{ secrets.TF_API_TOKEN }}
          HARNESS_PLATFORM_API_KEY: ${{ secrets.HARNESS_API_KEY }}
        run: tofu apply -auto-approve
```

---

## Migration: Moving to Remote Backend

If you've already deployed locally:

```bash
cd harness-organization/

# 1. Create backend.tf
cat > backend.tf <<EOF
terraform {
  backend "remote" {
    organization = "your-tfe-org"
    workspaces {
      name = "harness-org-example-one"
    }
  }
}
EOF

# 2. Migrate state
tofu init -migrate-state

# 3. Verify
tofu plan  # Should show no changes

# State is now in TFE!
```

---

## Best Practices

1. **Naming Convention:** Use consistent workspace/key names
   - `harness-org-{org-identifier}`
   - `harness-account-setup`

2. **State Locking:** Enable state locking (TFE does this automatically)

3. **Access Control:** 
   - Separate TFE workspaces = separate access control
   - Can give teams access to only their org

4. **Tagging:** Tag all resources with org identifier for tracking

5. **Documentation:** Keep a README in each org directory explaining what it manages

---

## Summary

| Approach | Best For | Pros | Cons |
|----------|----------|------|------|
| **Workspaces** | Small teams, simple setup | Easy switching, single directory | Shared tfvars, manual switching |
| **Separate Dirs** | Production, CI/CD, large teams | Complete isolation, no confusion | More directories |
| **S3 Keys** | Existing S3 backends | Works with current setup | Manual key management |

**My Recommendation:** Start with **Workspaces** for simplicity, migrate to **Separate Directories** as you grow.
