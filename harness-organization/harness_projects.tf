locals {
  org_projects = local.merged_sources["projects"]
}

module "harness_project" {
  depends_on = [
    module.git_connector,
    module.aws_cloud_provider_connector,
    module.gcp_cloud_provider_connector,
    harness_platform_secret_text.org_secrets,
    harness_platform_secret_file.org_secrets,
  ]
  source = "../harness-project"
  for_each = {
    for p in local.org_projects :
    coalesce(
      try(p.cnf.identifier, null),
      replace(replace(p.name, " ", "_"), "-", "_")
    ) => p
  }

  organization_id = resource.harness_platform_organization.selected.id
  default_project_template = try(coalesce(
    # If the config is defined in the projects/<project_name>/config.yaml
    try(each.value.cnf.default_project_template, null),
    # If the config is defined in the organisasions/<org_name>/config.yaml
    local.default_project_template
  ), null)

  configs_root             = local.platform_configs_dir
  org_root                 = "${local.platform_configs_dir}/organizations/${var.organization_name}"
  project_key              = each.value.name
  harness_platform_account = var.harness_platform_account
  harness_platform_url     = var.harness_platform_url
  project_id               = try(each.value.cnf.identifier, null)
  project_name             = each.value.name
  project_description      = lookup(each.value.cnf, "description", "Harness Project managed by Solutions Factory")
}
