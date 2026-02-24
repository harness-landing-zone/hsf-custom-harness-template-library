locals {
  connector_files_path = "${local.source_directory}/git-connectors"

  connector_files = fileset("${local.connector_files_path}/", "*.yaml")

  connectors = flatten([
    for connector_file in local.connector_files : [
      merge(
        yamldecode(file("${local.connector_files_path}/${connector_file}")),
        {
          identifier = replace(replace(replace(connector_file, ".yaml", ""), " ", "_"), "-", "_")
          name = lookup(
            try(yamldecode(file("${local.connector_files_path}/${connector_file}")), {}),
            "name",
            replace(replace(replace(connector_file, ".yaml", ""), "-", "_"), "_", " ")
          )
        }
      )
    ]
  ])
}



module "git_connector" {
  source = "../modules/git-connectors"
  for_each = {
    for connector in local.connectors : connector.identifier => connector
  }

  connector_type        = each.value.type
  connector_name        = each.value.name
  connector_identifier  = each.value.identifier
  connector_description = try(lookup(each.value, "description", null), "Harness UserGroup managed by Solutions Factory")
  connector_tags = flatten([
    [for k, v in lookup(each.value, "tags", {}) : "${k}:${v}"],
    local.common_tags_tuple
  ])

  git_connector_url   = each.value.connector_url
  connection_type     = each.value.connection_type
  validation_repo     = try(each.value.validation_repo, null)
  execute_on_delegate = try(each.value.execute_on_delegate, false)
  delegate_selectors  = try(each.value.delegate_selectors, [])

  git_connector_http_credentials = try(each.value.http_credentials, null)
  git_connector_ssh_credentials  = try(each.value.ssh_credentials, null)
  git_connector_api_auth         = try(each.value.api_auth, null)
}

