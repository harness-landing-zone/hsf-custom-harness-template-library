
locals {
  org_identifier = coalesce(var.organization_id, replace(replace(var.organization_name, " ", "_"), "-", "_"))
}

module "harness_platform_setup" {
  count  = var.create_account ? 1 : 0
  source = "../harness-platform-setup"

  harness_platform_account = var.harness_platform_account
  harness_platform_url     = var.harness_platform_url
  tags                     = var.tags
}

data "harness_platform_organization" "existing" {
  count      = var.create_project && !var.create_organization ? 1 : 0
  identifier = local.org_identifier
}

module "harness_organization" {
  count  = var.create_organization ? 1 : 0
  source = "../harness-organization"

  organization_name         = var.organization_name
  harness_platform_account  = var.harness_platform_account
  harness_platform_url      = var.harness_platform_url
  tags                      = var.tags
  configs_relative_path     = var.configs_relative_path
  git_connector_credentials = var.git_connector_credentials
}

module "harness_project" {
  depends_on = [module.harness_organization]
  count      = var.create_project ? 1 : 0
  source     = "../harness-project"

  organization_id          = try(data.harness_platform_organization.existing[0].identifier, local.org_identifier)
  project_id               = var.project_id
  project_name             = var.project_name
  project_key              = var.project_name
  configs_root             = var.configs_relative_path
  org_root                 = "${var.configs_relative_path}/organizations/${var.organization_name}"
  harness_platform_account = var.harness_platform_account
  harness_platform_url     = var.harness_platform_url
  tags                     = var.tags
}
