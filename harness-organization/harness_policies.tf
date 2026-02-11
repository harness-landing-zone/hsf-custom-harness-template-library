locals {
  policies = local.merged_sources["policies"]
}


resource "harness_platform_policy" "policies" {
  lifecycle {
    ignore_changes = [
      git_commit_msg,
      git_connector_ref,
      git_path,
      git_repo,
      git_branch,
      git_base_branch,
      git_is_new_branch,
      git_import
    ]
  }
  for_each = {
    for policy in local.policies : policy.name => policy
  }
  identifier  = each.value.identifier
  name        = each.value.name
  description = lookup(each.value, "description", "Harness Policy managed by Solutions Factory")
  rego        = each.value.payload

  tags = flatten([
    [for k, v in lookup(each.value, "tags", {}) : "${k}:${v}"],
    local.common_tags_tuple
  ])
}
