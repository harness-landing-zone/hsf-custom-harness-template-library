locals {
  cloud_provider_connectors = local.merged_sources["cloud-provider-connectors"]
}

module "aws_oidc_cloud_provider_connector" {
  source = "../modules/cloud-provider-connectors"
  for_each = {
    for connector in local.cloud_provider_connectors : connector.identifier => connector
    if lower(lookup(connector.cnf, "type", "aws")) == "aws" && lower(lookup(connector.cnf, "auth_type", "oidc")) == "oidc"
  }

  org_id = data.harness_platform_organization.selected.id

  connector_name        = lookup(each.value.cnf, "name", each.value.name)
  connector_identifier  = each.value.identifier
  connector_description = lookup(each.value.cnf, "description", "Harness AWS connector managed by Solutions Factory")
  connector_tags = flatten([
    [for k, v in lookup(each.value.cnf, "tags", {}) : "${k}:${v}"],
    local.common_tags_tuple
  ])

  execute_on_delegate = try(each.value.cnf.execute_on_delegate, false)
  force_delete        = try(each.value.cnf.force_delete, false)

  # This wiring intentionally supports AWS OIDC only.
  aws_connector_oidc_authentication = {
    iam_role_arn       = each.value.cnf.oidc_authentication.iam_role_arn
    delegate_selectors = toset(try(each.value.cnf.oidc_authentication.delegate_selectors, []))
    region             = try(each.value.cnf.oidc_authentication.region, null)
  }

  aws_connector_cross_account_access = try(each.value.cnf.cross_account_access, null)
}
