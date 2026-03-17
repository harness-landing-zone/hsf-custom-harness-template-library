locals {
  services = local.merged_sources["services"]
}

resource "harness_platform_service" "services" {
  for_each = {
    for service in local.services : service.name => service
  }

  identifier  = each.value.identifier
  name        = each.value.name
  org_id      = data.harness_platform_organization.selected.id
  project_id  = data.harness_platform_project.selected.id
  description = lookup(each.value.cnf, "description", "Harness Service managed by Solutions Factory")
  tags = flatten([
    [for k, v in lookup(each.value.cnf, "tags", {}) : "${k}:${v}"],
    local.common_tags_tuple
  ])

  yaml = lookup(each.value.cnf, "yaml", {}) != {} ? replace(yamlencode(each.value.cnf.yaml), "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:") : ""

}
