locals {
  pipelines = local.merged_sources["pipelines"]
}

resource "harness_platform_pipeline" "pipelines" {
  depends_on = [data.harness_platform_project.selected]

  for_each = {
    for k, p in local.pipelines :
    coalesce(try(p.cnf.identifier, null), p.identifier) => p
  }

  identifier  = coalesce(try(each.value.cnf.identifier, null), each.value.identifier)
  name        = each.value.name
  org_id      = data.harness_platform_organization.selected.id
  project_id  = data.harness_platform_project.selected.id
  description = lookup(each.value.cnf, "description", "Pipeline managed by Solutions Factory")
  # Load the raw Harness pipeline YAML from .harness/ in the template library root,
  # then inject the actual org and project identifiers created above.
  yaml = replace(
    replace(
      file("${var.configs_root}/.harness/${lookup(each.value.cnf, "yaml_source", each.value.identifier)}.yaml"),
      "orgIdentifier: default",
      "orgIdentifier: ${data.harness_platform_organization.selected.id}"
    ),
    "projectIdentifier: default",
    "projectIdentifier: ${data.harness_platform_project.selected.id}"
  )
}
