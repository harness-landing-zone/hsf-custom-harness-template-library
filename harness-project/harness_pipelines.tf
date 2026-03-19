locals {
  pipelines = local.merged_sources["pipelines"]
}

resource "harness_platform_pipeline" "pipelines" {
  depends_on = [data.harness_platform_project.selected]

  for_each = {
    for k, p in local.pipelines :
    coalesce(try(p.cnf.identifier, null), p.identifier) => p
  }

  identifier      = coalesce(try(each.value.cnf.identifier, null), each.value.identifier)
  name            = each.value.name
  org_id          = data.harness_platform_organization.selected.id
  project_id      = data.harness_platform_project.selected.id
  description     = lookup(each.value.cnf, "description", "Pipeline managed by Solutions Factory")
  import_from_git = true

  git_import_info {
    branch_name   = lookup(each.value.cnf, "git_branch", "main")
    file_path     = lookup(each.value.cnf, "git_file_path", ".harness/${each.key}.yaml")
    connector_ref = lookup(each.value.cnf, "git_connector_ref", "")
    repo_name     = lookup(each.value.cnf, "git_repo_name", "")
  }

  pipeline_import_request {
    pipeline_name        = each.value.name
    pipeline_description = lookup(each.value.cnf, "description", "Pipeline managed by Solutions Factory")
  }
}
