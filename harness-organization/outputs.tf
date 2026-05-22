locals {

  organization_url = join("/",
    [
      trimsuffix(replace(var.harness_platform_url, "gateway", "ng"), "/"),
      "account",
      var.harness_platform_account,
      "all/orgs",
      data.harness_platform_organization.selected.id,
      "projects"
    ]
  )
}

output "organization_identifier" {
  description = "Organization Identifier"
  value       = data.harness_platform_organization.selected.identifier
}

output "organization_url" {
  value = local.organization_url
}

output "organization_name" {
  value = data.harness_platform_organization.selected
}

output "platform_configs_dir" {
  value = local.platform_configs_dir
}
output "source_directory" {
  value = local.source_directory
}

output "org_directory" {
  value = local.org_directory
}
