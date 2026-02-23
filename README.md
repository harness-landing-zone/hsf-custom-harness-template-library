# Custom Harness Template Library

OpenTofu/Terraform templates for managing a Harness account, organizations, and projects on `app.harness.io` using the `harness/harness` provider.

## What This Repo Does

This repository is organized around three operational entrypoints:

- `harness-platform-setup/`: account-level baseline resources
- `harness-organization/`: organization creation + org-scoped resources + project discovery/orchestration
- `harness-project/`: reusable single-project module used directly or by `harness-organization`

Important naming note:

- There is no top-level `harness-projects/` directory.
- Project discovery/orchestration is implemented in `harness-organization/harness-projects.tf`, which instantiates the reusable `harness-project/` module once per discovered project folder.

## Architecture (Scope and RBAC)

The repo intentionally separates responsibilities by Harness scope:

- Account scope (`harness-platform-setup`)
  - Account-level roles
  - Account-level resource groups
  - Account-level user groups and role assignments
  - Account-level policies and policy sets
  - Account-level environments/overrides (from local templates)
- Organization scope (`harness-organization`)
  - Creates the organization
  - Applies org-scoped roles, resource groups, user groups, role assignments, policies, policy sets, environments, and git connectors
  - Discovers project folders and calls `harness-project/` for each project
- Project scope (`harness-project`)
  - Creates the project
  - Applies project-scoped roles, resource groups, user groups, role assignments, policies, policy sets, environments, and git connectors

RBAC conventions this repo is designed to support (intentional and non-overlapping):

- `iacm_workspace_*` permissions are project-scoped only
- `iacm-developer` is project-scoped
- `iacm-admin` is account-scoped
- Developer role is CD pipelines only and has zero IACM permissions
- Environment access is granted through Resource Groups (not role permissions directly)

## Discovery and Config Resolution

### Organization Discovery (`harness-organization`)

`harness-organization` resolves configuration using:

- Global templates: `platform-configs/templates/`
- Optional org-specific overrides: `platform-configs/organizations/<organization_name>/`

Behavior (preserved):

- `var.organization_name` maps directly to the org folder name.
- If `platform-configs/organizations/<organization_name>/` exists, files in that folder override matching global template files.
- If the folder does not exist, execution falls back to global defaults only.

Org/project discovery is file-driven via `fileset()` patterns:

- Organizations/projects are discovered from `**/config.yaml` (folder-based keys)
- Other categories (`groups`, `roles`, `environments`, `resource_groups`, `policy_sets`, `git-connectors`, `cloud-provider-connectors`, `policies`) are merged by relative file path

### Project Discovery and Defaults (`harness-organization/harness-projects.tf` + `harness-project`)

Project creation is orchestrated from `harness-organization/harness-projects.tf`:

- Discovered project folders under:
  - `platform-configs/organizations/<organization>/projects/*/config.yaml`
- Each discovered project is passed into the `harness-project/` module with:
  - `org_root`
  - `project_key`
  - project name/description from folder config (when present)

Within `harness-project/`, project-scoped resources are merged from:

- Global defaults: `harness-project/templates/`
- Optional project-specific overrides: `<org_root>/projects/<project_key>/`

Behavior (preserved):

- If a project folder contains category files (for example `groups/*.yaml`, `roles/*.yaml`, `git-connectors/*.yaml`), those override same-path defaults from `harness-project/templates/`.
- If a project folder omits a category/file, `harness-project/templates/` defaults are used (path-based fallback).

## Folder Structure

Key directories:

```text
.
├── harness-platform-setup/          # Account-level baseline resources
├── harness-organization/            # Org creation + org resources + project discovery
├── platform-configs/
│   ├── templates/                   # Global org/project overlay defaults
│   └── organizations/
│       └── <Organization Name>/     # Org-specific config and project folders
│           ├── config.yaml
│           ├── groups/
│           ├── roles/
│           ├── resource_groups/
│           ├── environments/
│           ├── policies/
│           ├── policy_sets/
│           ├── git-connectors/
│           ├── cloud-provider-connectors/
│           └── projects/
│               └── <Project Name>/
│                   ├── config.yaml
│                   ├── groups/
│                   ├── roles/
│                   ├── resource_groups/
│                   ├── environments/
│                   ├── policies/
│                   ├── policy_sets/
│                   ├── git-connectors/
│                   └── cloud-provider-connectors/
├── harness-project/                 # Reusable single-project entrypoint/module
│   └── templates/                   # Project defaults (envs/roles/groups/connectors/etc.)
├── modules/
│   ├── git-connectors/
│   └── cloud-provider-connectors/   # AWS cloud provider connector module (wired in account/org/project entrypoints)
├── scaffolds/                       # Template scaffolding and local docs
├── providers.tf.example             # Provider config template (copy to providers.tf)
└── README.md
```

## Inputs and Credentials

### Provider Credentials (Environment Variables)

Use environment variables for credentials (preferred and required by this repo's operating rules). `providers.tf.example` supports env var fallback.

- `HARNESS_ACCOUNT_ID`
- `HARNESS_PLATFORM_API_KEY`
- `HARNESS_ENDPOINT` (optional; defaults to Harness SaaS gateway URL if not set)

Setup pattern:

1. Copy `providers.tf.example` into the entrypoint directory you are running as `providers.tf` (gitignored).
2. Export credentials in your shell.
3. Keep secrets out of `terraform.tfvars`.

## EntryPoint Variables

### `harness-platform-setup/`

Required:

- `harness_platform_account`

Optional:

- `harness_platform_url` (default `https://app.harness.io/gateway`)
- `tags`

### `harness-organization/`

Required:

- `harness_platform_account`
- `organization_name`

Optional:

- `harness_platform_url` (default `https://app.harness.io/gateway`)
- `organization_id` (otherwise derived from `organization_name`)
- `organization_description`
- `tags`
- `projects` (declared, but project discovery is normally file/folder driven via repo-root `platform-configs/`)

### `harness-project/`

Required:

- `harness_platform_account`
- `organization_id`
- `project_name`

Optional:

- `harness_platform_url` (default `https://app.harness.io/gateway`)
- `project_id` (otherwise derived from `project_name`)
- `project_description`
- `tags`
- `templates_root`
- `org_root`
- `project_key`

Note:

- `org_root` and `project_key` are used by `harness-organization/harness-projects.tf` when orchestrating project discovery.
- `templates_root` is declared/passed, but the current `harness-project/` implementation reads defaults from `harness-project/templates/` directly.

## Workflow (OpenTofu / Local State)

This repo uses local state only.

- Do not configure a remote backend.
- Run from the specific entrypoint directory you are targeting (`harness-platform-setup/`, `harness-organization/`, or `harness-project/`).
- Standard workflow:
  - `tofu init`
  - `tofu validate`
  - `tofu plan`
- Do not run `tofu apply` unless explicitly intended and approved.
- Review plan output carefully and flag any `destroy` actions before proceeding.

Example (organization onboarding + project discovery):

```bash
cd harness-organization
cp ../providers.tf.example providers.tf

# Prefer env vars for credentials
export HARNESS_ACCOUNT_ID="<account_id>"
export HARNESS_PLATFORM_API_KEY="<api_key>"
# export HARNESS_ENDPOINT="https://app.harness.io/gateway" # optional

cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and set at least:
# - harness_platform_account (can also come from env via provider vars)
# - organization_name

tofu init
tofu validate
tofu plan
```

Example (account baseline setup):

```bash
cd harness-platform-setup
cp ../providers.tf.example providers.tf
cp terraform.tfvars.example terraform.tfvars

tofu init
tofu validate
tofu plan
```

## Provider / Resource Notes

The current code declares:

- `harness/harness` provider `>= 0.31`
- `hashicorp/time` provider `~> 0.9.1`

Resource names and scope usage in this README were checked against the Harness Terraform provider documentation via Terraform MCP (for example `harness_platform_organization`, `harness_platform_project`, `harness_platform_roles`, `harness_platform_resource_group`, `harness_platform_usergroup`, `harness_platform_role_assignments`, `harness_platform_policy`, `harness_platform_policyset`, `harness_platform_environment`).

## References (Official Harness Docs)

- Harness Terraform onboarding: https://developer.harness.io/docs/platform/get-started/terraform-onboard
- Harness organizations and projects: https://developer.harness.io/docs/platform/organizations-and-projects/
- RBAC in Harness: https://developer.harness.io/docs/platform/role-based-access-control/rbac-in-harness/
- Manage roles: https://developer.harness.io/docs/platform/role-based-access-control/add-manage-roles/
- Manage user groups: https://developer.harness.io/docs/platform/role-based-access-control/add-manage-user-groups/
- Add resource groups: https://developer.harness.io/docs/platform/role-based-access-control/add-resource-groups/
- IaCM roles and permissions (workspace permissions reference): https://developer.harness.io/docs/infra-as-code-management/roles-and-permissions/#view-permissions-for-the-workspace

## Developer Guides

Repo scaffolding and contributor guides are in:

- `scaffolds/README.md`
- `CONTRIBUTING.md`

## License

MIT License. See `LICENSE`.
