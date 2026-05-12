# Examples and Troubleshooting Guide

Practical examples and solutions to common issues.

## Example 1: Create Your First Organization with Projects

### Step-by-Step

**1. Create the organization structure:**
```bash
mkdir -p platform-configs/organizations/MyCompany/projects/{Backend,Frontend,Mobile}
```

**2. Create org config:**
```bash
cat > platform-configs/organizations/MyCompany/config.yaml <<'EOF'
name: "MyCompany"
description: "Main company organization"
tags:
  environment: production
  managed_by: platform-team
EOF
```

**3. Create project configs:**
```bash
# Backend project
cat > platform-configs/organizations/MyCompany/projects/Backend/config.yaml <<'EOF'
name: "Backend Services"
description: "All backend microservices"
tags:
  team: backend
  language: go
EOF

# Frontend project
cat > platform-configs/organizations/MyCompany/projects/Frontend/config.yaml <<'EOF'
name: "Frontend Applications"
description: "Web and mobile frontends"
tags:
  team: frontend
  language: typescript
EOF

# Mobile project
cat > platform-configs/organizations/MyCompany/projects/Mobile/config.yaml <<'EOF'
name: "Mobile Apps"
description: "iOS and Android apps"
tags:
  team: mobile
  language: kotlin
EOF
```

**4. Deploy:**
```bash
cd harness-organization/
cat > terraform.tfvars <<EOF
harness_platform_account = "your-account-id"
organization_name        = "MyCompany"
EOF

export HARNESS_PLATFORM_API_KEY="your-api-key"
make init
make plan    # Review what will be created
make apply   # Create it!
```

**Result:** 1 org + 3 projects created automatically! ✨

## Example 2: Override a Template with Org-Specific Config

### Scenario
The default Developer role has basic permissions, but your Engineering org needs more.

**1. Check what's in the template:**
```bash
cat harness-organization/templates/roles/examples/Developer.yaml
```

**2. Create org override:**
```bash
mkdir -p platform-configs/organizations/Engineering/roles

cat > platform-configs/organizations/Engineering/roles/Developer.yaml <<'EOF'
name: "Senior Developer"
description: "Engineering developers with elevated permissions"
permissions:
  - core_pipeline_view
  - core_pipeline_execute
  - core_pipeline_edit        # ← Added
  - core_environment_view
  - core_environment_access   # ← Added
  - core_service_view
  - core_service_edit         # ← Added
  - core_connector_view
  - core_secret_view
EOF
```

**3. Re-deploy:**
```bash
cd harness-organization/
make plan   # You'll see the role with more permissions
make apply
```

**Result:** Engineering org gets custom role, but other orgs still use template version!

## Example 3: Add Org-Specific Group

### Scenario
Only Engineering org needs a "Data Engineers" group.

```bash
mkdir -p platform-configs/organizations/Engineering/groups

cat > platform-configs/organizations/Engineering/groups/Data_Engineers.yaml <<'EOF'
name: "Data Engineers"
description: "Team managing data pipelines"
tags:
  team: data
  purpose: engineering

role_bindings:
  - role: Developer
    resource_group: _all_resources_including_child_scopes
EOF
```

Re-deploy: `cd harness-organization && make apply`

**Result:** Only Engineering org has this group!

## Example 4: Project-Specific Environment

### Scenario
The "Mobile" project needs special environments.

```bash
mkdir -p platform-configs/organizations/MyCompany/projects/Mobile/environments

cat > platform-configs/organizations/MyCompany/projects/Mobile/environments/TestFlight.yaml <<'EOF'
name: "TestFlight"
type: PreProduction
description: "iOS TestFlight environment"
tags:
  platform: ios
  distribution: testflight
EOF

cat > platform-configs/organizations/MyCompany/projects/Mobile/environments/PlayStore_Beta.yaml <<'EOF'
name: "Play Store Beta"
type: PreProduction
description: "Android Play Store Beta track"
tags:
  platform: android
  distribution: play-beta
EOF
```

Re-deploy the org: `cd harness-organization && make apply`

**Result:** Mobile project has custom environments!

## Example 5: Using Multiple Template Sets

### Scenario
You want stricter defaults for production orgs.

**1. Create alternate templates:**
```bash
mkdir -p harness-organization/templates-strict/roles
cp harness-organization/templates/roles/Developer.yaml \
   harness-organization/templates-strict/roles/Developer.yaml

# Edit templates-strict/roles/Developer.yaml to remove risky permissions
```

**2. Configure org to use it:**
```bash
cat > platform-configs/organizations/Production/config.yaml <<'EOF'
name: "Production"
description: "Production organization"
default_org_template: "templates-strict"   # ← Use stricter templates
tags:
  environment: production
  criticality: high
EOF
```

**Result:** Production org uses strict templates, others use normal templates!

## Troubleshooting

### Issue 1: "No such file or directory" error

**Error:**
```
Error: Error in function call

Call to function "file" failed: no such file or directory.
```

**Cause:** Organization name in tfvars doesn't match folder name.

**Solution:**
```bash
# Check folder name
ls platform-configs/organizations/

# Ensure terraform.tfvars matches exactly (case-sensitive!)
organization_name = "Engineering"  # Must match folder name
```

### Issue 2: No projects created

**Symptom:** Org is created but no projects appear.

**Debug:**
```bash
# Check if project folders exist
ls platform-configs/organizations/YourOrg/projects/

# Each project MUST have config.yaml
ls platform-configs/organizations/YourOrg/projects/*/config.yaml

# Check Terraform plan
cd harness-organization && make plan | grep "module.harness_project"
```

**Common causes:**
- Missing `config.yaml` in project folder
- Folder name has special characters
- Empty projects/ directory

**Solution:**
```bash
# Ensure structure is correct
platform-configs/
└── organizations/
    └── YourOrg/
        └── projects/
            └── ProjectName/
                └── config.yaml  # ← Must exist!
```

### Issue 3: Permission validation fails

**Error:**
```
Error: Invalid permissions found in role 'developer':
  core_pipeline_destroy

Valid permissions list: https://apidocs.harness.io/...
```

**Cause:** Permission name is wrong or not available at this scope.

**Solution:**
```bash
# 1. Check current valid permissions
curl -H "x-api-key: $HARNESS_PLATFORM_API_KEY" \
  "https://app.harness.io/gateway/authz/api/permissions?accountIdentifier=YOUR_ACCOUNT_ID"

# 2. Fix the permission name in your YAML
# Replace "core_pipeline_destroy" with "core_pipeline_delete"
```

### Issue 4: Resource already exists

**Error:**
```
Error: resource already exists

A resource with identifier "developers" already exists.
```

**Cause:** Resource was created outside Terraform or in another run.

**Solution Option 1 - Import:**
```bash
cd harness-organization
terraform import \
  'harness_platform_usergroup.usergroup["developers"]' \
  developers
```

**Solution Option 2 - Remove from state:**
```bash
# If you don't want Terraform to manage it
terraform state rm 'harness_platform_usergroup.usergroup["developers"]'
```

**Solution Option 3 - Prefix with underscore:**
```bash
# Rename file to tell Terraform it already exists
mv platform-configs/organizations/Eng/groups/developers.yaml \
   platform-configs/organizations/Eng/groups/_developers.yaml

# Or add scope_level in YAML
echo "scope_level: account" >> .../groups/developers.yaml
```

### Issue 5: Changes not applying

**Symptom:** You edited YAML but Terraform says "No changes."

**Debug:**
```bash
# 1. Check if file is in the right location
find platform-configs -name "yourfile.yaml"

# 2. Validate YAML syntax
python3 -c "import yaml; yaml.safe_load(open('yourfile.yaml'))"

# 3. Check Terraform is reading it
cd harness-organization
terraform console
> local.merged_sources["groups"]
```

**Common causes:**
- File in wrong directory
- Invalid YAML syntax
- Cached Terraform plan

**Solution:**
```bash
# Clear cache and re-plan
rm -rf .terraform/
rm terraform.tfstate.backup
make init
make plan
```

### Issue 6: Docker permission denied

**Error:**
```
permission denied while trying to connect to Docker daemon
```

**Cause:** Docker not running or user not in docker group.

**Solution Option 1 - Start Docker:**
```bash
# macOS
open -a Docker

# Linux
sudo systemctl start docker
```

**Solution Option 2 - Skip Docker:**
```bash
# Install tofu/terraform locally
brew install opentofu

# Run directly instead of via Make
cd harness-organization/
tofu init
tofu plan -var-file=terraform.tfvars
tofu apply -var-file=terraform.tfvars
```

### Issue 7: Identifier conflicts

**Error:**
```
Error: Duplicate resource identifier
```

**Cause:** Two files generate the same identifier.

Example:
```
groups/my-group.yaml      → identifier: my_group
groups/my_group.yaml      → identifier: my_group  (conflict!)
```

**Solution:** Use explicit identifiers in YAML:
```yaml
# groups/my-special-group.yaml
identifier: my_special_group_v2  # ← Explicit
name: "My Special Group"
```

### Issue 8: Merge behavior not working as expected

**Symptom:** Org override not being used.

**Debug:**
```bash
# Check both locations
ls harness-organization/templates/groups/
ls platform-configs/organizations/YourOrg/groups/

# Ensure filenames match EXACTLY
# These are different:
templates/groups/Developer.yaml
configs/groups/developer.yaml    # ← Won't override (case difference)

# Add debug output
cd harness-organization
terraform console
> local.merged_sources["groups"]["Developer"]
```

**Solution:** Ensure exact filename match (case-sensitive).

## Advanced Examples

### Example 6: Conditional Resources

Create groups only for specific orgs:

```yaml
# platform-configs/organizations/Engineering/groups/Oncall.yaml
name: "On-Call Engineers"
description: "24/7 on-call rotation"
# This file only exists in Engineering org
# Other orgs won't have this group
```

### Example 7: Nested Project Structure

Use subdirectories in projects:

```bash
platform-configs/organizations/Engineering/projects/
├── Backend-Services/
│   └── config.yaml
├── Backend-Infrastructure/
│   └── config.yaml
└── Frontend-Web/
    └── config.yaml

# Each folder = one project
# Folder names become identifiers
```

### Example 8: Custom Identifier Override

Override auto-generated identifiers:

```yaml
# config.yaml
name: "My Super Cool Project!"
identifier: my_project   # ← Use this instead of "My_Super_Cool_Project_"
description: "Custom identifier"
```

### Example 9: Tags Inheritance

```yaml
# Org config.yaml
tags:
  department: engineering
  cost_center: "1234"

# Project config.yaml inherits org tags
# Plus adds its own:
tags:
  team: platform
  service: api
```

## Best Practices

### 1. Naming Conventions

**Good:**
```
groups/Developers.yaml
groups/Release_Managers.yaml
roles/Senior_Developer.yaml
```

**Avoid:**
```
groups/dev's & qa's.yaml        # Special characters
groups/My Group (v2).yaml       # Parentheses
roles/developer.yaml            # Use consistent casing
```

### 2. File Organization

```
platform-configs/organizations/Engineering/
├── config.yaml              # Org metadata
├── groups/                  # Override groups
│   └── SRE_Team.yaml
├── roles/                   # Override roles
│   └── SRE.yaml
└── projects/
    ├── Platform/
    │   ├── config.yaml      # Project metadata
    │   └── groups/          # Project-specific groups
    │       └── Platform_Admins.yaml
    └── Observability/
        └── config.yaml
```

### 3. Version Control

```bash
# Good commit message
git commit -m "Add Mobile project to Engineering org

- Created Mobile/config.yaml
- Added TestFlight and PlayStore environments
- Configured mobile-specific developer group"

# Tag releases
git tag -a v1.2.0 -m "Added 3 new projects"
```

### 4. Testing Changes

```bash
# Always plan before apply
make plan > plan.txt
cat plan.txt  # Review carefully

# Test in dev account first
export HARNESS_ACCOUNT_ID="dev-account"
make apply

# Then promote to prod
export HARNESS_ACCOUNT_ID="prod-account"
make apply
```

## Debugging Techniques

### Technique 1: Terraform Console

```bash
cd harness-organization/
terraform console

# Inspect merged sources
> local.merged_sources["groups"]

# Check specific project
> local.merged_sources["projects"]["Backend"]

# See what will be created
> keys(local.merged_sources["projects"])
```

### Technique 2: Add Temporary Outputs

```hcl
# outputs.tf
output "debug_all_projects" {
  value = {
    for k, v in local.merged_sources["projects"] : k => {
      name   = v.name
      origin = v.origin
      file   = v.file
    }
  }
}
```

Then: `make plan` and see the output.

### Technique 3: Trace File Reading

```bash
# Enable Terraform debug logging
export TF_LOG=DEBUG
make plan 2>&1 | grep "config.yaml"

# See what files are being read
```

### Technique 4: Validate YAML

```bash
# Check all YAML files are valid
find platform-configs -name "*.yaml" -exec \
  python3 -c "import sys, yaml; yaml.safe_load(open(sys.argv[1]))" {} \;

# Or use yamllint
yamllint platform-configs/
```

## Quick Reference

### Common Commands

```bash
# Initialize
cd harness-organization && make init

# Preview changes
make plan

# Apply changes
make apply

# Destroy everything (careful!)
make destroy

# Format code
make fmt

# Run without Docker (if you have tofu installed)
tofu init
tofu plan -var-file=terraform.tfvars
tofu apply -var-file=terraform.tfvars
```

### File Locations

| Resource Type | Template Location | Override Location |
|---------------|-------------------|-------------------|
| Org config | N/A | `platform-configs/organizations/<OrgName>/config.yaml` |
| Org groups | `harness-organization/templates/groups/` | `platform-configs/organizations/<OrgName>/groups/` |
| Org roles | `harness-organization/templates/roles/` | `platform-configs/organizations/<OrgName>/roles/` |
| Projects | N/A | `platform-configs/organizations/<OrgName>/projects/<ProjectName>/config.yaml` |
| Project groups | `harness-project/templates/groups/` | `platform-configs/organizations/<OrgName>/projects/<ProjectName>/groups/` |

### Key Variables

```hcl
# terraform.tfvars
harness_platform_account = "abc123xyz"        # Required
organization_name        = "Engineering"       # Required (must match folder)
organization_id          = "engineering"       # Optional (overrides auto-generated)
default_org_template     = "templates"         # Optional (default template folder)
tags                     = {env = "prod"}      # Optional (additional tags)
```

## Getting Help

1. **Check logs:** `export TF_LOG=DEBUG && make plan`
2. **Use console:** `terraform console` to inspect locals
3. **Add outputs:** Temporary debug outputs
4. **Validate YAML:** Use yamllint or Python
5. **Compare with working example:** Check `platform-configs/organizations/Example Org One/`

Remember: The system is complex but logical. Trace the data flow:
```
YAML file → locals-merge.tf → merged_sources → for_each → resource
```
