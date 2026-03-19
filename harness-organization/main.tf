resource "harness_platform_organization" "selected" {
  identifier  = local.org_identifier
  name        = local.org_name
  description = local.org_description

  tags = local.common_tags_tuple
}

data "harness_platform_organization" "selected" {
  identifier = harness_platform_organization.selected.id
}

data "harness_platform_permissions" "current" {}
