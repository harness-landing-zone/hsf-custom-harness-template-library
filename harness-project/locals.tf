locals {
  required_tags = {
    created_by : "Terraform"
    harnessSolutionsFactory : "true"
  }

  common_tags = merge(
    var.tags,
    local.required_tags
  )

  # Harness Tags are read into Terraform as a standard Map entry but needs to be
  # converted into a list of key:value entries
  common_tags_tuple = [for k, v in local.common_tags : "${k}:${v}"]


  fmt_identifier = (
    var.project_id == null
    ?
    replace(
      replace(
        var.project_name,
        " ",
        "_"
      ),
      "-",
      "_"
    )
    :
    var.project_id
  )

  # Attempt to read the org-level config.yaml if it exists.
  # Falls back to an empty map if the file is not present.
  project_config = try(
    yamldecode(file("${local.org_directory}/config.yaml")),
    {}
  )

  # Use the name from config.yaml if defined, otherwise fall back to the variable.
  project_name = try(local.project_config.name, var.project_name)
}
