
module "harness_project" {
  depends_on = [data.harness_platform_organization.selected]
  source     = "../harness-project"
  for_each = {
    for p in local.merged_sources["projects"] : p.identifier => p
  }
  organization_id          = local.fmt_identifier
  templates_root           = "${path.module}/platform-configs/templates"
  org_root                 = "${path.module}/platform-configs/organizations/${var.organization_name}"
  project_key              = each.key
  harness_platform_account = var.harness_platform_account
  harness_platform_url     = var.harness_platform_url
  project_name             = each.value.name
  project_description      = lookup(each.value.cnf, "description", "Harness Project managed by Solutions Factory")
}
