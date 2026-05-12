# Quick Reference Card

One-page cheat sheet for the repository.

## TL;DR - How It Works

**Add folder → Get resource automatically**

```bash
mkdir platform-configs/organizations/MyOrg/projects/NewProject
echo "name: New Project" > .../NewProject/config.yaml
cd harness-organization && make apply
# ✓ Project created in Harness!
```

## Directory Structure

```
├── harness-platform-setup/      # Run once per account
├── harness-organization/        # Run once per org (auto-discovers projects)
├── harness-project/             # Reusable module (called by org)
└── platform-configs/            # Your customizations
    └── organizations/
        └── <OrgName>/           # ← Folder = Org
            ├── config.yaml
            ├── groups/          # Override templates
            └── projects/
                └── <ProjectName>/   # ← Folder = Project
                    └── config.yaml
```

## Three Entrypoints

| Entrypoint | Purpose | When to Run | Creates |
|------------|---------|-------------|---------|
| `harness-platform-setup/` | Account baseline | Once per account | Account-level roles, groups, policies |
| `harness-organization/` | Org + projects | Once per org | 1 org + all discovered projects |
| `harness-project/` | Single project | Rarely (org does it) | 1 project |

## Common Commands

```bash
# Deploy account setup
cd harness-platform-setup/
export HARNESS_PLATFORM_API_KEY="your-key"
cat > terraform.tfvars <<EOF
harness_platform_account = "your-account-id"
tags = {}
EOF
make init && make plan && make apply

# Deploy organization + projects
cd ../harness-organization/
cat > terraform.tfvars <<EOF
harness_platform_account = "your-account-id"
organization_name        = "Engineering"
EOF
make init && make plan && make apply

# Run without Docker (if tofu installed)
tofu init
tofu plan -var-file=terraform.tfvars
tofu apply -var-file=terraform.tfvars
```

## The Merge System

Templates provide defaults, configs override them:

```
Template:                    Override:
templates/                   platform-configs/
  groups/                      organizations/MyOrg/
    Developer.yaml               groups/
      permissions: [5]             Developer.yaml    ← WINS!
                                     permissions: [10]

Result: MyOrg gets 10 permissions
```

Same filename = override. Different filename = addition.

## File Naming Rules

| Filename | Becomes Identifier | Usage |
|----------|-------------------|-------|
| `Developer.yaml` | `Developer` | New group |
| `_Existing_Group.yaml` | `Existing_Group` | Reference existing |
| `My Team.yaml` | `My_Team` | Spaces → underscores |
| `my-role.yaml` | `my_role` | Dashes → underscores |

Override identifier in YAML:
```yaml
identifier: custom_id
name: "Display Name"
```

## config.yaml Structure

### Organization config.yaml
```yaml
name: "Organization Name"
description: "Description"
identifier: "custom_org_id"              # Optional
default_org_template: "templates"        # Optional
default_project_template: "templates"    # Optional
tags:
  key: value
```

### Project config.yaml
```yaml
name: "Project Name"
description: "Description"
identifier: "custom_project_id"          # Optional
default_project_template: "templates"    # Optional (overrides org default)
tags:
  key: value
```

## Resource YAML Examples

### Group (groups/GroupName.yaml)
```yaml
name: "Display Name"
description: "Description"
tags:
  purpose: development

role_bindings:
  - role: developer
    resource_group: _all_resources_including_child_scopes
  - role: viewer
    resource_group: production_only
```

### Existing Group (groups/_ExistingGroup.yaml)
```yaml
scope_level: account   # Marks as existing
name: "Existing Group"

role_bindings:
  - role: custom_role
    resource_group: _all_account_level_resources
```

### Role (roles/RoleName.yaml)
```yaml
name: "Display Name"
description: "Description"
permissions:
  - core_pipeline_view
  - core_pipeline_execute
  - core_environment_view
```

### Resource Group (resource_groups/GroupName.yaml)
```yaml
name: "Production Environments"
description: "Access to prod only"
include_child_scopes: true

resource_filters:
  - type: ENVIRONMENT
    filters:
      - name: type
        values:
          - Production
```

### Environment (environments/EnvName.yaml)
```yaml
name: "Production"
type: Production    # or PreProduction
description: "Production environment"
tags:
  criticality: high
```

## Built-in Identifiers

### Roles
- `_account_admin`
- `_account_viewer`
- `_organization_admin`
- `_organization_viewer`
- `_project_admin`
- `_project_viewer`

### Resource Groups
- `_all_account_level_resources`
- `_all_resources_including_child_scopes`
- `_all_organization_level_resources`
- `_all_project_level_resources`

## Common Workflows

### Add New Organization
```bash
# 1. Create structure
mkdir -p platform-configs/organizations/NewOrg

# 2. Create config
cat > platform-configs/organizations/NewOrg/config.yaml <<'EOF'
name: "New Org"
description: "Description"
tags:
  env: prod
EOF

# 3. Deploy
cd harness-organization/
cat > terraform.tfvars <<EOF
harness_platform_account = "your-id"
organization_name        = "NewOrg"
EOF
make apply
```

### Add New Project
```bash
# 1. Create folder + config
mkdir -p platform-configs/organizations/ExistingOrg/projects/NewProject
cat > .../NewProject/config.yaml <<'EOF'
name: "New Project"
description: "Description"
EOF

# 2. Re-run org terraform (auto-discovers)
cd harness-organization/
make apply
```

### Override Template
```bash
# 1. Create override file
mkdir -p platform-configs/organizations/MyOrg/groups
cp harness-organization/templates/groups/Developer.yaml \
   platform-configs/organizations/MyOrg/groups/Developer.yaml

# 2. Edit with custom settings
vim platform-configs/organizations/MyOrg/groups/Developer.yaml

# 3. Re-deploy
cd harness-organization && make apply
```

### Add Org-Specific Resource
```bash
# 1. Create new file (not in templates)
cat > platform-configs/organizations/MyOrg/groups/CustomGroup.yaml <<'EOF'
name: "Custom Group"
role_bindings:
  - role: custom_role
    resource_group: _all_resources_including_child_scopes
EOF

# 2. Deploy
cd harness-organization && make apply
```

## Troubleshooting Quick Fixes

| Problem | Quick Fix |
|---------|-----------|
| No projects created | Check `projects/*/config.yaml` exists |
| "File not found" | Verify `organization_name` matches folder name exactly |
| "Resource exists" | Prefix filename with `_` or add `scope_level: account` |
| "Invalid permission" | Check API docs, fix permission name |
| Changes not applying | `rm -rf .terraform/ && make init plan` |
| Docker error | Install tofu/terraform locally, run directly |
| Identifier conflict | Add explicit `identifier:` in YAML |

## Debug Commands

```bash
# See what will be created
make plan | grep "will be created"

# Inspect merged sources
terraform console
> local.merged_sources["projects"]

# Enable debug logging
export TF_LOG=DEBUG
make plan

# Validate YAML syntax
python3 -c "import yaml; yaml.safe_load(open('file.yaml'))"

# Check which files are being read
make plan 2>&1 | grep "config.yaml"
```

## Key Terraform Locals

```hcl
local.org_directory           # platform-configs/organizations/<OrgName>
local.source_directory        # harness-organization/templates
local.merged_sources          # Result of merge (what gets created)
local.merged_sources["projects"]   # Discovered projects
local.merged_sources["groups"]     # Merged groups
```

## Environment Variables

```bash
# Required
export HARNESS_PLATFORM_API_KEY="your-key-here"

# Optional (can be in terraform.tfvars instead)
export HARNESS_ACCOUNT_ID="your-account-id"
export HARNESS_ENDPOINT="https://app.harness.io/gateway"

# Debug
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform.log
```

## File Locations Summary

| What | Template | Override |
|------|----------|----------|
| Org groups | `harness-organization/templates/groups/` | `platform-configs/organizations/<Org>/groups/` |
| Org roles | `harness-organization/templates/roles/` | `platform-configs/organizations/<Org>/roles/` |
| Org envs | `harness-organization/templates/environments/` | `platform-configs/organizations/<Org>/environments/` |
| Projects | N/A (config-only) | `platform-configs/organizations/<Org>/projects/<Project>/config.yaml` |
| Project groups | `harness-project/templates/groups/` | `platform-configs/organizations/<Org>/projects/<Project>/groups/` |

## Pro Tips

1. **Always plan first:** `make plan > plan.txt` then review
2. **Test in dev account first** before production
3. **Use descriptive folder names** - they become identifiers
4. **Keep templates generic** - put customizations in platform-configs
5. **Version control everything** - including terraform.tfstate (or use remote backend)
6. **Document custom configs** - Add comments in YAML
7. **Use tags consistently** - They help track resources
8. **Watch for case sensitivity** - Folder/file names must match exactly

## Getting Help

📖 **Documentation:**
- `HOW_IT_WORKS.md` - Detailed architecture explanation
- `ARCHITECTURE_DIAGRAM.md` - Visual diagrams
- `EXAMPLES_AND_TROUBLESHOOTING.md` - Practical examples
- `README.md` - Original documentation

🐛 **Debugging:**
1. Check logs: `export TF_LOG=DEBUG && make plan`
2. Use console: `terraform console` to inspect locals
3. Validate YAML: `yamllint platform-configs/`
4. Compare with working example: See `platform-configs/organizations/Example Org One/`

## Remember

**The Pattern:**
```
Folder structure → locals-merge.tf → merged_sources → for_each → Resources
```

**The Power:**
```
mkdir = create resource (convention over configuration)
```

**The Safety:**
```
make plan (always review before apply!)
```
