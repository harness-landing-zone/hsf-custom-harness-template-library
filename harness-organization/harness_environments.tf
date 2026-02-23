locals {

  environments = local.merged_sources["environments"]



  environment_overrides = flatten([
    for override in local.environments : [
      override
    ] if lookup(override, "yaml", {}) != {}
  ])
}

resource "harness_platform_environment" "environments" {
  for_each = {
    for environment in local.environments : environment.name => environment
  }

  identifier = each.value.identifier

  name        = each.value.name
  org_id      = data.harness_platform_organization.selected.id
  type        = lookup(each.value.cnf, "type", "PreProduction")
  description = lookup(each.value.cnf, "description", "Harness Environment managed by Solutions Factory")
  tags = flatten([
    [for k, v in lookup(each.value.cnf, "tags", {}) : "${k}:${v}"],
    local.common_tags_tuple
  ])

}

resource "harness_platform_overrides" "example" {
  for_each = {
    for environment in local.environment_overrides : environment.identifier => environment
  }
  env_id = "account.dev"
  type   = "ENV_GLOBAL_OVERRIDE"
  yaml   = lookup(each.value, "yaml", {}) != {} ? replace(yamlencode(each.value.yaml), "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:") : ""
  # yaml   = lookup(each.value, "yaml", {}) != {} ? yamlencode(each.value.yaml) : ""
}
