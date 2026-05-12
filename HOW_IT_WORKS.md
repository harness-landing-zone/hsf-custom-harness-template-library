# How This Repository Works - Deep Dive

Your peer built something really clever here. Let me break down the architecture.

## Core Concept: Convention Over Configuration

**The Magic:** Add a folder → Get a resource automatically created

```
platform-configs/
└── organizations/
    └── My Cool Org/              ← Folder name = Org name
        ├── config.yaml           ← Org settings
        └── projects/
            ├── Project A/        ← Folder name = Project name
            │   └── config.yaml
            └── Project B/
                └── config.yaml
```

Run `harness-organization/` → Both org and all projects are created!

## Architecture: Three Layers

### Layer 1: Templates (Defaults)
```
harness-organization/templates/
├── groups/
│   └── Developers.yaml          ← Default developer group
├── roles/
│   └── Developer.yaml           ← Default developer role
└── environments/
    ├── dev.yaml
    └── prod.yaml
```

**Purpose:** Ship sensible defaults that work out of the box

### Layer 2: Platform Configs (Overrides)
```
platform-configs/
└── organizations/
    └── My Org/
        ├── groups/
        │   └── Developers.yaml   ← Overrides template version
        └── projects/
            └── Project A/
                └── config.yaml
```

**Purpose:** Customize per-org or per-project

### Layer 3: Merge Logic
The clever part - Terraform automatically merges layers 1 & 2.

## The Merge System: How It Works

### Step 1: Directory Discovery

`locals-merge.tf` defines "categories" of resources:

```hcl
categories = {
  projects = {
    global_dir = "${local.source_directory}/projects"        # Layer 1
    org_dir    = "${local.org_directory}/projects"           # Layer 2
    patterns   = ["**/config.yaml"]                          # What to find
    key_fn     = "folder"                                    # Use folder name as key
  }
  
  groups = {
    global_dir = "${local.source_directory}/groups"
    org_dir    = "${local.org_directory}/groups"
    patterns   = ["*.yaml"]
    key_fn     = "path"                                      # Use file path as key
  }
}
```

### Step 2: File Discovery

For each category, scan both directories:

```hcl
merged_sources = {
  for cat, cfg in local.categories :
  cat => merge(
    # Scan global/template directory
    {
      for rel in fileset(cfg.global_dir, cfg.patterns) :
      key => {
        origin = "global"
        file   = rel
        cnf    = yamldecode(file("${cfg.global_dir}/${rel}"))
      }
    },
    # Scan org-specific directory (OVERWRITES global if same key)
    {
      for rel in fileset(cfg.org_dir, cfg.patterns) :
      key => {
        origin = "org"
        file   = rel
        cnf    = yamldecode(file("${cfg.org_dir}/${rel}"))
      }
    }
  )
}
```

**Key insight:** `merge()` means org version wins if the key matches!

### Step 3: Key Generation

Two strategies based on `key_fn`:

**Folder-based (projects):**
```
projects/Project A/config.yaml → key = "Project A"
projects/Project B/config.yaml → key = "Project B"
```

**Path-based (everything else):**
```
groups/Developers.yaml → key = "Developers"
groups/team/Ops.yaml   → key = "team/Ops"
```

### Step 4: Resource Creation

Projects use the merged data:

```hcl
module "harness_project" {
  for_each = local.merged_sources["projects"]  # ← Loop over discovered projects
  
  source              = "../harness-project"
  organization_id     = local.fmt_identifier
  project_name        = each.value.name
  project_description = lookup(each.value.cnf, "description", "...")
}
```

## Real Example: Let's Trace It

### Setup
```
harness-organization/templates/
└── groups/
    └── Developers.yaml          # Default: 5 permissions

platform-configs/organizations/Engineering/
├── config.yaml                  # Org: "Engineering"
├── groups/
│   └── Developers.yaml          # Custom: 10 permissions
└── projects/
    ├── Backend/
    │   └── config.yaml
    └── Frontend/
        └── config.yaml
```

### Deploy Command
```bash
cd harness-organization/
cat > terraform.tfvars <<EOF
harness_platform_account = "abc123"
organization_name        = "Engineering"
EOF
make deploy
```

### What Happens

**Step 1: Locals Resolve**
```hcl
local.org_directory = "../platform-configs/organizations/Engineering"
local.source_directory = "./templates"
```

**Step 2: Org Config Read**
```hcl
local.org_config = yamldecode(file("../platform-configs/organizations/Engineering/config.yaml"))
local.org_name = "Engineering"
```

**Step 3: Merge Groups**

Scan `templates/groups/*.yaml`:
```hcl
{
  "Developers" => {
    origin = "global"
    file   = "Developers.yaml"
    cnf    = { permissions = [5 items] }
  }
}
```

Scan `platform-configs/organizations/Engineering/groups/*.yaml`:
```hcl
{
  "Developers" => {
    origin = "org"              # ← This wins!
    file   = "Developers.yaml"
    cnf    = { permissions = [10 items] }
  }
}
```

Result: Engineering org gets custom 10-permission developer group

**Step 4: Discover Projects**

Scan `templates/projects/*/config.yaml`: (none)

Scan `platform-configs/organizations/Engineering/projects/*/config.yaml`:
```hcl
{
  "Backend" => {
    origin = "org"
    name   = "Backend"
    cnf    = { ...config.yaml contents... }
  },
  "Frontend" => {
    origin = "org"
    name   = "Frontend"
    cnf    = { ...config.yaml contents... }
  }
}
```

**Step 5: Create Resources**
```hcl
# Org created
harness_platform_organization.selected {
  name = "Engineering"
}

# Projects created via module loop
module.harness_project["Backend"]
module.harness_project["Frontend"]

# Group created with org-specific config
harness_platform_usergroup.usergroup["Developers"] {
  permissions = [10 items from org config]
}
```

## The Module Pattern: Nested Discovery

Each project module **repeats this pattern** at project scope!

`harness-project/main.tf`:
```hcl
locals {
  # Same merge logic but for project scope
  project_dir = "${var.org_root}/projects/${var.project_key}"
  source_dir  = "${path.module}/templates"
  
  # Merge project-level resources
  merged_sources = {
    groups = merge(
      fileset("${source_dir}/groups", "*.yaml"),
      fileset("${project_dir}/groups", "*.yaml")
    )
  }
}
```

So projects can also have templates + overrides!

## Why This Is Clever

### 1. **Self-Service**
Developers can add a project by:
```bash
mkdir -p platform-configs/organizations/MyOrg/projects/NewProject
cat > platform-configs/organizations/MyOrg/projects/NewProject/config.yaml <<EOF
name: "New Project"
description: "My new project"
EOF

# Re-run org terraform
cd harness-organization && make deploy
```

No code changes needed!

### 2. **DRY (Don't Repeat Yourself)**
Common configs in templates/, exceptions in platform-configs/

### 3. **Multi-Tenancy**
Each org can customize without affecting others:
```
platform-configs/
└── organizations/
    ├── Engineering/
    │   └── groups/Developers.yaml    # 10 permissions
    └── Marketing/
        └── groups/Developers.yaml    # 3 permissions
```

### 4. **Hierarchical Overrides**
```
Project inherits from → Org inherits from → Account (platform-setup)
```

### 5. **GitOps Ready**
Everything is declarative. PR to add folder = PR to add project.

## The Identifier Magic

Files are named, but identifiers are derived:

```hcl
identifier = replace(replace(replace(filename, ".yaml", ""), " ", "_"), "-", "_")
```

So:
- `My Developer Role.yaml` → identifier = `My_Developer_Role`
- `team-leads.yaml` → identifier = `team_leads`

You can override in YAML:
```yaml
# groups/My Custom Group.yaml
identifier: custom_id    # ← Use this instead of filename-derived
name: "My Custom Group"
```

## The Docker/Makefile Wrapper

Why Docker?

```makefile
DOCKER_RUN = docker run --rm -it \
  -v ${PROJECT_DIR}:${WORKDIR} \
  ghcr.io/opentofu/opentofu:${TERRAFORM_VERSION}
```

**Benefits:**
1. **Version pinning** - Everyone uses same Terraform version
2. **No local install** - Works on any machine with Docker
3. **Isolated** - Doesn't pollute local environment
4. **CI/CD ready** - Same command everywhere

**Tradeoff:** Adds complexity for debugging

## Directory Structure - Full Picture

```
.
├── harness-platform-setup/          # Layer 1: Account baseline
│   ├── templates/                   # Default account resources
│   │   ├── groups/
│   │   ├── roles/
│   │   └── ...
│   └── *.tf                         # Terraform to create them
│
├── harness-organization/            # Layer 2: Org + auto-discover projects
│   ├── templates/                   # Default org resources
│   ├── locals-merge.tf              # ← THE MERGE MAGIC
│   ├── harness-projects.tf          # ← PROJECT AUTO-DISCOVERY
│   └── *.tf
│
├── harness-project/                 # Layer 3: Reusable project module
│   ├── templates/                   # Default project resources
│   └── *.tf                         # Called by org OR standalone
│
└── platform-configs/                # Your customizations
    └── organizations/
        └── <Org Name>/              # ← Folder = Org
            ├── config.yaml          # Org metadata
            ├── groups/              # Override org-level defaults
            ├── roles/
            └── projects/
                └── <Project Name>/  # ← Folder = Project
                    ├── config.yaml
                    └── groups/      # Override project-level defaults
```

## Key Files Explained

### `locals-merge.tf`
The brain. Defines what to scan and how to merge.

### `harness-projects.tf`
Loops over discovered projects and calls the project module for each.

### `config.yaml` Structure

**Org level:**
```yaml
name: "My Organization"
description: "Description here"
identifier: "my_org"                      # Optional override
default_org_template: "templates"         # Which template folder to use
default_project_template: "templates"     # Default for all projects
tags:
  owner: platform-team
```

**Project level:**
```yaml
name: "My Project"
description: "Project description"
identifier: "my_project"                  # Optional override
default_project_template: "templates-two" # Override org default
tags:
  team: backend
```

## How to Use This System

### 1. Initial Account Setup
```bash
cd harness-platform-setup/
cp terraform.tfvars.example terraform.tfvars
# Edit with your account ID
export HARNESS_PLATFORM_API_KEY="..."
make deploy
```

### 2. Create Your First Org
```bash
# Create org config
mkdir -p platform-configs/organizations/Engineering
cat > platform-configs/organizations/Engineering/config.yaml <<EOF
name: "Engineering"
description: "Engineering organization"
tags:
  department: engineering
EOF

# Deploy org
cd harness-organization/
cat > terraform.tfvars <<EOF
harness_platform_account = "abc123"
organization_name        = "Engineering"
EOF
make deploy
```

### 3. Add Projects (The Magic Part!)
```bash
# Just create folders!
mkdir -p platform-configs/organizations/Engineering/projects/Backend
cat > platform-configs/organizations/Engineering/projects/Backend/config.yaml <<EOF
name: "Backend Services"
description: "Backend microservices"
tags:
  team: platform
EOF

mkdir -p platform-configs/organizations/Engineering/projects/Frontend
cat > platform-configs/organizations/Engineering/projects/Frontend/config.yaml <<EOF
name: "Frontend Apps"
description: "User-facing applications"
tags:
  team: web
EOF

# Re-run org terraform - projects auto-discovered!
cd harness-organization/
make deploy
```

### 4. Customize Resources
```bash
# Override default developer group for Engineering org
mkdir -p platform-configs/organizations/Engineering/groups
cat > platform-configs/organizations/Engineering/groups/Developers.yaml <<EOF
name: "Engineering Developers"
description: "Custom permissions for engineering devs"
tags:
  purpose: development
role_bindings:
  - role: custom_engineering_role
    resource_group: _all_resources_including_child_scopes
EOF

# Re-run
cd harness-organization && make deploy
```

## Common Patterns

### Pattern 1: Shared Defaults
Put common configs in `templates/` so all orgs/projects get them.

### Pattern 2: Org-Specific
Override in `platform-configs/organizations/<OrgName>/`

### Pattern 3: Project-Specific
Override in `platform-configs/organizations/<OrgName>/projects/<ProjectName>/`

### Pattern 4: Multiple Template Sets
```hcl
# In config.yaml
default_org_template: "templates-strict"     # Use templates-strict/ folder
```

Then create `harness-organization/templates-strict/` with different defaults.

## Debugging Tips

### See What Will Be Created
```bash
cd harness-organization/
make plan | grep "will be created"
```

### Check Merged Config
Add temporary output:
```hcl
# outputs.tf
output "debug_merged_projects" {
  value = local.merged_sources["projects"]
}
```

### Trace Which File Won
The `origin` field tells you:
```hcl
origin = "global"  # From templates/
origin = "org"     # From platform-configs/ (wins!)
```

## Summary

Your peer built a **templated, multi-tenant, self-service IaC system** where:

1. **Templates provide defaults** (`harness-*/templates/`)
2. **Folders auto-create resources** (`platform-configs/organizations/`)
3. **Overrides work via merge** (org files overwrite template files)
4. **Projects are discovered** (any folder under `projects/`)
5. **Everything is declarative** (add folder → get resource)

It's complex but powerful. Once you understand the merge system, it's actually quite elegant!

## Next Steps to Master It

1. **Read `locals-merge.tf`** - This is the key file
2. **Trace a project creation** - Add a project folder, run with debug output
3. **Experiment with overrides** - Add same-named file in org and template, see which wins
4. **Study the module pattern** - See how project module reuses the org pattern

Your peer knows their Terraform! This is production-grade stuff.
