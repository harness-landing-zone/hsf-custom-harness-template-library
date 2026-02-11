locals {
  source_directory = "${path.module}/templates"
  org_directory    = "${var.org_root}/projects/${var.project_key}"

  categories = {

    # everything else: key by relative file path (dev.yaml, team/foo.yaml, etc.)
    environments = {
      global_dir = "${local.source_directory}/environments"
      org_dir    = "${local.org_directory}/environments"
      patterns   = ["*.yaml"]
      key_fn     = "path"
    }

    groups = {
      global_dir = "${local.source_directory}/groups"
      org_dir    = "${local.org_directory}/groups"
      patterns   = ["*.yaml"]
      key_fn     = "path"
    }

    resource_groups = {
      global_dir = "${local.source_directory}/resource_groups"
      org_dir    = "${local.org_directory}/resource_groups"
      patterns   = ["*.yaml"]
      key_fn     = "path"
    }

    policy_sets = {
      global_dir = "${local.source_directory}/policy_sets"
      org_dir    = "${local.org_directory}/policy_sets"
      patterns   = ["*.yaml"]
      key_fn     = "path"
    }

    policies = {
      global_dir = "${local.source_directory}/policies"
      org_dir    = "${local.org_directory}/policies"
      patterns   = ["*.rego"]
      key_fn     = "path"
    }
    roles = {
      global_dir = "${local.source_directory}/roles"
      org_dir    = "${local.org_directory}/roles"
      patterns   = ["*.yaml"]
      key_fn     = "path"
    }
  }

  # helper: compute the key for a given category + relative file
  # - "path"           -> "dev.yaml" / "team/a.yaml" / "project1/config.yaml"
  # - "folder" -> "project1" from "project1/config.yaml"
  merged_sources = {
    for cat, cfg in local.categories :
    cat => merge(
      {
        for rel in distinct(flatten([for p in cfg.patterns : try(fileset(cfg.global_dir, p), [])])) :
        (cfg.key_fn == "folder" ? basename(dirname(rel)) : replace(rel, ".yaml", "")) => {
          origin = "global"
          name   = cfg.key_fn == "folder" ? basename(dirname(rel)) : replace(rel, ".yaml", "")
          identifier = cfg.key_fn == "project_folder" ? basename(dirname(rel)) : replace(replace(replace(rel, ".yaml", ""), " ", "_"), "-", "_")
          dir    = cfg.global_dir
          file   = rel
          cnf    = try(yamldecode(file("${cfg.global_dir}/${rel}")), {})
        }
      },
      {
        for rel in distinct(flatten([for p in cfg.patterns : try(fileset(cfg.org_dir, p), [])])) :
        (cfg.key_fn == "folder" ? basename(dirname(rel)) : replace(rel, ".yaml", "")) => {
          origin = "org"
          name   = cfg.key_fn == "folder" ? basename(dirname(rel)) : replace(rel, ".yaml", "")
          identifier = cfg.key_fn == "project_folder" ? basename(dirname(rel)) : replace(replace(replace(rel, ".yaml", ""), " ", "_"), "-", "_")
          dir    = cfg.org_dir
          file   = rel
          cnf    = try(yamldecode(file("${cfg.org_dir}/${rel}")), {})
        }
      }
    )
  }

}

output "merged_sources" {
  value = local.merged_sources
}