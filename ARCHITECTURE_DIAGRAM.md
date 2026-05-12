# Architecture Diagrams

Visual representation of how the system works.

## High-Level Flow

```
┌─────────────────────────────────────────────────────────────┐
│  Platform Configs (Your Customizations)                     │
│  platform-configs/organizations/                            │
│    └── Engineering/                    ┌──────────────────┐ │
│        ├── config.yaml                 │ Add Folder =     │ │
│        ├── groups/                     │ Get Resource!    │ │
│        └── projects/                   └──────────────────┘ │
│            ├── Backend/                                      │
│            │   └── config.yaml                              │
│            └── Frontend/                                     │
│                └── config.yaml                              │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ Merges with ↓
                          │
┌─────────────────────────────────────────────────────────────┐
│  Templates (Defaults)                                        │
│  harness-organization/templates/                            │
│    ├── groups/                                              │
│    ├── roles/                                               │
│    └── projects/                                            │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ Processed by ↓
                          │
┌─────────────────────────────────────────────────────────────┐
│  Terraform (locals-merge.tf)                                │
│  • Scans both directories                                   │
│  • Merges YAML files by name                                │
│  • Org overrides win                                        │
│  • Creates resources via for_each                           │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ Creates ↓
                          │
┌─────────────────────────────────────────────────────────────┐
│  Harness Resources                                          │
│  • 1 Organization: Engineering                              │
│  • 2 Projects: Backend, Frontend                            │
│  • N Groups, Roles, etc. (merged)                           │
└─────────────────────────────────────────────────────────────┘
```

## File Merge Logic

```
Template File                   Override File
┌──────────────────┐           ┌──────────────────┐
│ templates/       │           │ platform-configs/│
│   groups/        │           │   org/           │
│   Developer.yaml │           │   groups/        │
│                  │           │   Developer.yaml │
│ permissions:     │           │                  │
│   - read         │    VS     │ permissions:     │
│   - write        │           │   - read         │
│   - execute      │           │   - write        │
│                  │           │   - execute      │
│                  │           │   - delete       │
│                  │           │   - admin        │
└──────────────────┘           └──────────────────┘
         │                              │
         └──────────┬───────────────────┘
                    │
                    ↓
         ┌────────────────────┐
         │  OVERRIDE WINS!    │
         │  Uses org version  │
         │  (5 permissions)   │
         └────────────────────┘
```

## Project Auto-Discovery

```
                    Run: make deploy
                           │
                           ↓
┌──────────────────────────────────────────────────────────┐
│ 1. Variable: organization_name = "Engineering"           │
└──────────────────────────────────────────────────────────┘
                           │
                           ↓
┌──────────────────────────────────────────────────────────┐
│ 2. Resolve Paths                                         │
│    org_dir = "../platform-configs/organizations/         │
│               Engineering"                               │
└──────────────────────────────────────────────────────────┘
                           │
                           ↓
┌──────────────────────────────────────────────────────────┐
│ 3. Scan for Projects                                     │
│    fileset("${org_dir}/projects", "**/config.yaml")      │
│                                                          │
│    Found:                                                │
│    • Backend/config.yaml                                 │
│    • Frontend/config.yaml                                │
│    • Mobile/config.yaml                                  │
└──────────────────────────────────────────────────────────┘
                           │
                           ↓
┌──────────────────────────────────────────────────────────┐
│ 4. Extract Keys (folder names)                           │
│    {                                                     │
│      "Backend": {                                        │
│        name: "Backend",                                  │
│        cnf: {...config contents...}                      │
│      },                                                  │
│      "Frontend": {...},                                  │
│      "Mobile": {...}                                     │
│    }                                                     │
└──────────────────────────────────────────────────────────┘
                           │
                           ↓
┌──────────────────────────────────────────────────────────┐
│ 5. Create Resources via for_each                         │
│    module "harness_project" {                            │
│      for_each = {discovered projects}                    │
│      source = "../harness-project"                       │
│      project_name = each.value.name                      │
│    }                                                     │
└──────────────────────────────────────────────────────────┘
                           │
                           ↓
┌──────────────────────────────────────────────────────────┐
│ 6. Result in Harness                                     │
│    ✓ Backend project created                             │
│    ✓ Frontend project created                            │
│    ✓ Mobile project created                              │
└──────────────────────────────────────────────────────────┘
```

## Three-Layer Architecture

```
┌────────────────────────────────────────────────────────────────┐
│  LAYER 1: Account Scope                                        │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │ harness-platform-setup/                                  │ │
│  │                                                          │ │
│  │ Creates:                                                 │ │
│  │  • Account-level roles                                   │ │
│  │  • Account-level resource groups                         │ │
│  │  • Account-level user groups                             │ │
│  │  • Account-level policies                                │ │
│  │                                                          │ │
│  │ Run once per Harness account                             │ │
│  └──────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘
                              │
                              │ Inherits from
                              ↓
┌────────────────────────────────────────────────────────────────┐
│  LAYER 2: Organization Scope                                   │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │ harness-organization/                                    │ │
│  │                                                          │ │
│  │ Creates:                                                 │ │
│  │  • 1 Organization                                        │ │
│  │  • Org-level roles, groups, etc.                         │ │
│  │  • Auto-discovers and creates all projects ✨            │ │
│  │                                                          │ │
│  │ Run once per org (can have multiple orgs)                │ │
│  └──────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘
                              │
                              │ Inherits from
                              ↓
┌────────────────────────────────────────────────────────────────┐
│  LAYER 3: Project Scope                                        │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │ harness-project/ (Module)                                │ │
│  │                                                          │ │
│  │ Creates:                                                 │ │
│  │  • 1 Project                                             │ │
│  │  • Project-level roles, groups, etc.                     │ │
│  │                                                          │ │
│  │ Called by org module (auto) OR standalone (manual)       │ │
│  └──────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘
```

## The Merge Process (Detailed)

```
Step 1: Define Categories
┌─────────────────────────────────────────┐
│ locals-merge.tf                         │
│                                         │
│ categories = {                          │
│   projects = {                          │
│     global_dir = "templates/projects"   │
│     org_dir = "configs/org/projects"    │
│     patterns = ["**/config.yaml"]       │
│   }                                     │
│   groups = {                            │
│     global_dir = "templates/groups"     │
│     org_dir = "configs/org/groups"      │
│     patterns = ["*.yaml"]               │
│   }                                     │
│ }                                       │
└─────────────────────────────────────────┘
                 │
                 ↓
Step 2: Scan Global Directory
┌─────────────────────────────────────────┐
│ fileset("templates/groups", "*.yaml")   │
│                                         │
│ Result:                                 │
│   ["Admin.yaml", "Developer.yaml"]      │
└─────────────────────────────────────────┘
                 │
                 ↓
Step 3: Build Global Map
┌─────────────────────────────────────────┐
│ {                                       │
│   "Admin" => {                          │
│     origin: "global",                   │
│     file: "Admin.yaml",                 │
│     cnf: {parsed YAML}                  │
│   },                                    │
│   "Developer" => {                      │
│     origin: "global",                   │
│     file: "Developer.yaml",             │
│     cnf: {parsed YAML}                  │
│   }                                     │
│ }                                       │
└─────────────────────────────────────────┘
                 │
                 ↓
Step 4: Scan Org Directory
┌─────────────────────────────────────────┐
│ fileset("configs/org/groups", "*.yaml") │
│                                         │
│ Result:                                 │
│   ["Developer.yaml", "ReleaseManager... │
└─────────────────────────────────────────┘
                 │
                 ↓
Step 5: Build Org Map
┌─────────────────────────────────────────┐
│ {                                       │
│   "Developer" => {                      │
│     origin: "org",         ← OVERRIDE! │
│     file: "Developer.yaml",             │
│     cnf: {custom YAML}                  │
│   },                                    │
│   "ReleaseManager" => {                 │
│     origin: "org",         ← NEW!      │
│     file: "ReleaseManager.yaml",        │
│     cnf: {parsed YAML}                  │
│   }                                     │
│ }                                       │
└─────────────────────────────────────────┘
                 │
                 ↓
Step 6: Merge (org overwrites global)
┌─────────────────────────────────────────┐
│ merge(global_map, org_map)              │
│                                         │
│ Result:                                 │
│ {                                       │
│   "Admin" => {origin: "global", ...},   │
│   "Developer" => {origin: "org", ...},  │
│   "ReleaseManager" => {origin:"org"...} │
│ }                                       │
└─────────────────────────────────────────┘
                 │
                 ↓
Step 7: Create Resources
┌─────────────────────────────────────────┐
│ resource "harness_platform_usergroup" { │
│   for_each = merged_map                 │
│   name = each.value.cnf.name            │
│   ...                                   │
│ }                                       │
│                                         │
│ Creates:                                │
│   • Admin (from template)               │
│   • Developer (from org override)       │
│   • ReleaseManager (org-only)           │
└─────────────────────────────────────────┘
```

## Data Flow: User Action to Harness Resource

```
Developer Action
┌─────────────────────────────────────────┐
│ mkdir platform-configs/organizations/   │
│       Engineering/projects/NewAPI       │
│                                         │
│ cat > .../NewAPI/config.yaml <<EOF      │
│ name: "New API"                         │
│ description: "New microservice"         │
│ EOF                                     │
│                                         │
│ git add . && git commit && git push     │
└─────────────────────────────────────────┘
                 │
                 ↓
CI/CD Pipeline
┌─────────────────────────────────────────┐
│ cd harness-organization/                │
│ make deploy                             │
└─────────────────────────────────────────┘
                 │
                 ↓
Terraform Execution
┌─────────────────────────────────────────┐
│ locals-merge.tf scans directories       │
│ • Found: NewAPI/config.yaml             │
│ • Extracted: name="New API"             │
│ • Added to: merged_sources["projects"]  │
└─────────────────────────────────────────┘
                 │
                 ↓
Module Invocation
┌─────────────────────────────────────────┐
│ module "harness_project" {              │
│   for_each = merged_sources["projects"] │
│   ...                                   │
│ }                                       │
│                                         │
│ Iteration: "NewAPI" => {config...}      │
└─────────────────────────────────────────┘
                 │
                 ↓
Harness API Call
┌─────────────────────────────────────────┐
│ POST /v1/orgs/Engineering/projects      │
│ {                                       │
│   "identifier": "NewAPI",               │
│   "name": "New API",                    │
│   "description": "New microservice"     │
│ }                                       │
└─────────────────────────────────────────┘
                 │
                 ↓
Result in Harness UI
┌─────────────────────────────────────────┐
│ ✓ Project "New API" created             │
│   under Engineering org                 │
└─────────────────────────────────────────┘
```

## Key Insight: The Power of `merge()`

```hcl
# This is the magic line in locals-merge.tf

merged_sources = {
  for cat, cfg in local.categories :
  cat => merge(
    {...global files...},
    {...org files...}     ← This overwrites global!
  )
}
```

When same key exists in both maps, **the second argument wins**.

```
merge(
  { "A" => 1, "B" => 2 },
  { "B" => 99, "C" => 3 }
)

Result: { "A" => 1, "B" => 99, "C" => 3 }
                        ↑
                    Org value won!
```

This is how org configs override templates!

## Summary

This architecture enables:
- ✅ **Self-service**: Add folder → Get resource
- ✅ **DRY**: Common configs in templates, exceptions in configs
- ✅ **Multi-tenancy**: Each org customizes independently  
- ✅ **GitOps**: Everything in version control
- ✅ **Scalability**: Add 100 projects = add 100 folders

Your peer built this well! 🎯
