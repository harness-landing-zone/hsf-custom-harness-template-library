locals {
  git_connectors = local.merged_sources["git-connectors"]
}



module "github_connector" {
  source = "../modules/git-connectors"
  for_each = {
    for connector in local.git_connectors : connector.identifier => connector
  }
  connector_type        = each.value.cnf.type
  org_id                = data.harness_platform_organization.selected.id
  connector_name        = each.value.cnf.name
  connector_identifier  = each.value.identifier
  connector_description = each.value.cnf.description
  connector_tags = flatten([
    [for k, v in lookup(each.value.cnf, "tags", {}) : "${k}:${v}"],
    local.common_tags_tuple
  ])
  git_connector_url   = each.value.cnf.connector_url
  connection_type     = each.value.cnf.connection_type
  validation_repo     = each.value.cnf.validation_repo
  execute_on_delegate = try(each.value.cnf.execute_on_delegate, false)
  delegate_selectors  = try(each.value.cnf.delegate_selectors, [])

  git_connector_http_credentials = try(each.value.cnf.github_app, null) != null ? {
    github_app = {
      application_id  = tostring(each.value.cnf.github_app.app_id)
      installation_id = tostring(each.value.cnf.github_app.installation_id)
      private_key_ref = each.value.cnf.github_app.private_key_ref
    }
  } : try(each.value.cnf.token_ref, null) != null ? {
    token_ref = each.value.cnf.token_ref
  } : null

  git_connector_ssh_credentials = try(each.value.cnf.ssh_key_ref, null) != null ? {
    ssh_key_ref = each.value.cnf.ssh_key_ref
  } : null

}


output "connectors" {
  value = local.git_connectors
}