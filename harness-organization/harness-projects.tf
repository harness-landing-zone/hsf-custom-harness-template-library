
module "harness_project" {
  depends_on = [data.harness_platform_organization.selected]
  source     = "../harness-project"
  for_each = {
    for p in local.merged_sources["projects"] :
    coalesce(
      try(p.cnf.identifier, null),
      replace(replace(p.name, " ", "_"), "-", "_")
    ) => p
  }
  organization_id          = local.fmt_identifier
  default_project_template = try(coalesce(
    # If the config is defined in the projects/<project_name>/config.yaml
    try(each.value.cnf.default_project_template, null),
    # If the config is defined in the organisasions/<org_name>/config.yaml
    local.default_project_template
  ), null)

  org_root                 = "${local.platform_configs_dir}/organizations/${var.organization_name}"
  project_key              = each.value.name
  harness_platform_account = var.harness_platform_account
  harness_platform_url     = var.harness_platform_url
  project_id               = try(each.value.cnf.identifier, null)
  project_name             = each.value.name
  project_description      = lookup(each.value.cnf, "description", "Harness Project managed by Solutions Factory")
}
