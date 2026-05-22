# Variable Loading - How It Works

## TL;DR - Where Variables Come From

When you run `tofu init/plan/apply` in `harness-organization/`:

```
Variables load from (in priority order):
1. terraform.tfvars (in harness-organization/ directory) ← YOU CREATE THIS
2. Environment variables (HARNESS_PLATFORM_API_KEY, etc.)
3. Default values in variables.tf
```

---

## Step-by-Step: Variable Loading Flow

### 1. You're in the directory:
```bash
cd harness-organization/
```

### 2. Terraform looks for variable files in THIS directory:
```
harness-organization/
├── terraform.tfvars        ← Terraform auto-loads this (YOU NEED TO CREATE IT!)
├── terraform.tfvars.json   ← Or this (JSON format)
├── *.auto.tfvars           ← Or any .auto.tfvars files
├── variables.tf            ← Defines what variables exist
└── providers.tf            ← Defines provider config
```

### 3. Variable Priority (highest to lowest):

```
1. Command line:  -var="organization_name=MyOrg"
2. terraform.tfvars file in CURRENT DIRECTORY
3. Environment variables (TF_VAR_*, HARNESS_*)
4. Default values in variables.tf
```

---

## Concrete Example

### Current State (What You Have):

```
harness-organization/
├── variables.tf          ← Defines: harness_platform_account, organization_name, etc.
├── providers.tf          ← Uses those variables
└── (NO terraform.tfvars) ← MISSING! This is what you need to create
```

### What Happens When You Run `tofu init`:

```bash
cd harness-organization/
tofu init

# Terraform looks for:
# 1. ./terraform.tfvars  → NOT FOUND (you need to create this)
# 2. Environment variables
# 3. Default values in variables.tf
```

---

## Where Variables Are DEFINED vs WHERE VALUES COME FROM

### DEFINED (variables.tf):
```hcl
# harness-organization/variables.tf

variable "harness_platform_account" {
  type        = string
  description = "[Required] Enter the Harness Platform Account Number"
}

variable "organization_name" {
  type        = string
  description = "[Required] New Organization Name"
  default     = null
}
```

This just says "these variables exist" - **NO VALUES YET**

### VALUES COME FROM (terraform.tfvars):
```hcl
# harness-organization/terraform.tfvars  ← YOU CREATE THIS FILE!

harness_platform_account = "abc123xyz"      ← Actual value
organization_name        = "Engineering"     ← Actual value
```

---

## Detailed Flow Diagram

```
Step 1: You run command
┌─────────────────────────────────────┐
│ cd harness-organization/            │
│ tofu plan                           │
└─────────────────────────────────────┘
           │
           ↓
Step 2: Terraform scans current directory
┌─────────────────────────────────────┐
│ Looking for variable files in:      │
│ /path/to/harness-organization/      │
│                                     │
│ Checking:                           │
│ ✓ terraform.tfvars                  │
│ ✓ *.auto.tfvars                     │
│ ✓ terraform.tfvars.json             │
└─────────────────────────────────────┘
           │
           ↓
Step 3: Load variables.tf (definitions)
┌─────────────────────────────────────┐
│ variables.tf defines:               │
│ - harness_platform_account (string) │
│ - organization_name (string)        │
│ - tags (map)                        │
└─────────────────────────────────────┘
           │
           ↓
Step 4: Load values from terraform.tfvars
┌─────────────────────────────────────┐
│ If terraform.tfvars exists:         │
│   harness_platform_account = "..."  │
│   organization_name = "..."         │
│                                     │
│ If NOT exists → Check env vars      │
│   TF_VAR_organization_name          │
│   HARNESS_ACCOUNT_ID                │
│                                     │
│ If still missing → Use defaults     │
│   (from variables.tf)               │
└─────────────────────────────────────┘
           │
           ↓
Step 5: Load providers.tf
┌─────────────────────────────────────┐
│ provider "harness" {                │
│   account_id = var.harness_...      │
│   platform_api_key = var....        │
│ }                                   │
│                                     │
│ Uses the loaded variable values     │
└─────────────────────────────────────┘
           │
           ↓
Step 6: Execution
┌─────────────────────────────────────┐
│ Now Terraform knows:                │
│ - Account ID: abc123xyz             │
│ - Org Name: Engineering             │
│ - API Key: (from env var)           │
│                                     │
│ Ready to create resources!          │
└─────────────────────────────────────┘
```

---

## What You Need to Do

### Option 1: Create terraform.tfvars (RECOMMENDED)

```bash
cd harness-organization/

# Create the file
cat > terraform.tfvars <<'EOF'
harness_platform_account = "your-account-id-here"
organization_name        = "Engineering"
tags = {
  managed_by = "terraform"
}
EOF
```

Then run:
```bash
tofu init
tofu plan    # Will use values from terraform.tfvars
```

### Option 2: Use environment variables

```bash
cd harness-organization/

# Set environment variables (note TF_VAR_ prefix!)
export TF_VAR_harness_platform_account="abc123"
export TF_VAR_organization_name="Engineering"

tofu init
tofu plan    # Will use environment variables
```

### Option 3: Pass on command line

```bash
cd harness-organization/

tofu plan \
  -var="harness_platform_account=abc123" \
  -var="organization_name=Engineering"
```

---

## Special Variables: Provider Credentials

Notice in `providers.tf`:

```hcl
variable "harness_platform_key" {
  default = null  # If Not passed, then ENV HARNESS_PLATFORM_API_KEY will be used
}

provider "harness" {
  platform_api_key = var.harness_platform_key
}
```

The API key can come from:
1. `terraform.tfvars`: `harness_platform_key = "pat.abc123..."` (NOT RECOMMENDED - sensitive!)
2. Environment variable: `export HARNESS_PLATFORM_API_KEY="pat.abc123..."` (RECOMMENDED)
3. Command line: `-var="harness_platform_key=..."` (NOT RECOMMENDED)

**Best practice:** Use environment variable for secrets!

---

## Complete Working Example

```bash
# 1. Navigate to org directory
cd /Users/anmolpandey/work/hsf-custom-harness-template-library/harness-organization

# 2. Create terraform.tfvars in THIS directory
cat > terraform.tfvars <<'EOF'
harness_platform_account = "abc123xyz"
organization_name        = "Engineering"
tags = {
  environment = "production"
  managed_by  = "terraform"
}
EOF

# 3. Set API key as environment variable (NOT in tfvars - it's sensitive!)
export HARNESS_PLATFORM_API_KEY="pat.your-api-key-here"

# 4. Initialize (downloads providers)
tofu init

# 5. Plan (shows what will be created)
tofu plan

# Terraform will:
# - Load harness_platform_account from terraform.tfvars
# - Load organization_name from terraform.tfvars
# - Load harness_platform_key from HARNESS_PLATFORM_API_KEY env var
# - Merge platform-configs/organizations/Engineering with templates/
# - Create org + all discovered projects
```

---

## Verification: Check What Terraform Sees

After creating terraform.tfvars, verify Terraform can read it:

```bash
cd harness-organization/

# Check variable values
tofu console

# In the console, type:
> var.harness_platform_account
"abc123xyz"

> var.organization_name
"Engineering"

> var.tags
{
  "environment" = "production"
  "managed_by" = "terraform"
}
```

---

## Common Mistakes

### ❌ Wrong: Creating tfvars in parent directory
```
hsf-custom-harness-template-library/
├── terraform.tfvars          ← WRONG! Terraform won't see this
└── harness-organization/
    └── (running tofu here)
```

### ✅ Right: Creating tfvars in same directory
```
harness-organization/
├── terraform.tfvars          ← RIGHT! Same directory where you run tofu
├── variables.tf
└── main.tf
```

### ❌ Wrong: Expecting platform-configs to have tfvars
```
platform-configs/
└── terraform.tfvars          ← NO! This directory is for YAML configs
```

### ✅ Right: tfvars goes where the .tf files are
```
harness-organization/         ← .tf files are here
└── terraform.tfvars          ← So tfvars goes here too
```

---

## The Makefile Approach

If you use the Makefile (with Docker), it passes the tfvars file explicitly:

```makefile
# From Makefile
plan: fmt
	${DOCKER_RUN} plan -var-file=${TERRAFORM_TFVARS}

# TERRAFORM_TFVARS defaults to "terraform.tfvars"
```

So `make plan` = `tofu plan -var-file=terraform.tfvars`

It's still looking for `terraform.tfvars` in the current directory!

---

## Summary

**Q: Where does tfvars load from?**  
**A: From the directory where you run `tofu` commands.**

```bash
cd harness-organization/          # You're here
tofu plan                         # Looks for terraform.tfvars HERE

# NOT in:
# - Parent directory
# - platform-configs/
# - templates/
# 
# Only in: harness-organization/terraform.tfvars
```

**What you need to create:**

```bash
# In harness-organization/ directory:
terraform.tfvars              ← Values for THIS deployment

# In harness-platform-setup/ directory:
terraform.tfvars              ← Different values for account setup

# In harness-project/ directory (if using standalone):
terraform.tfvars              ← Different values for project
```

Each entrypoint has its own `terraform.tfvars`!

---

## Quick Start Commands

```bash
# For account setup:
cd harness-platform-setup/
cat > terraform.tfvars <<EOF
harness_platform_account = "your-account-id"
tags = {}
EOF
export HARNESS_PLATFORM_API_KEY="your-key"
tofu init && tofu plan

# For organization:
cd ../harness-organization/
cat > terraform.tfvars <<EOF
harness_platform_account = "your-account-id"
organization_name = "Engineering"
EOF
export HARNESS_PLATFORM_API_KEY="your-key"
tofu init && tofu plan
```

Now you understand where the variables come from! 🎯
