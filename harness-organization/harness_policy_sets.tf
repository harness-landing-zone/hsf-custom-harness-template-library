locals {
  policy_sets = local.merged_sources["policy_sets"]
}

resource "harness_platform_policyset" "policy_sets" {
  for_each = {
    for policy_set in local.policy_sets : policy_set.name => policy_set
  }
  # Lifecycle hook to prevent errors in planning due to missing variables
  lifecycle {
    precondition {
      condition = alltrue([
        contains(keys(each.value.cnf), "identifier"),
        contains(keys(each.value.cnf), "name"),
        contains(keys(each.value.cnf), "action"),
        contains(keys(each.value.cnf), "type"),
        contains(["onrun", "onsave", "onstep"], lookup(each.value.cnf, "action", "missing-action"))
      ])
      error_message = <<EOF
      [Invalid] The following PolicySet (${each.key}) is invalid and missing one or more manadatory keys.
      - identifier
      - name
      - action
      - type

      Supported Action types are (depends on Policy Set type):
      - onrun
      - onsave
      - onstep
      EOF
    }
  }
  identifier = each.value.identifier
  name       = each.value.name
  action     = each.value.cnf.action
  type       = each.value.cnf.type
  enabled    = lookup(each.value.cnf, "enabled", true)

  dynamic "policy_references" {
    for_each = lookup(each.value.cnf, "policies", [])
    content {
      identifier = policy_references.value["identifier"]
      severity   = lookup(policy_references.value, "severity", "error")
    }
  }

  tags = flatten([
    [for k, v in lookup(each.value.cnf, "tags", {}) : "${k}:${v}"],
    local.common_tags_tuple
  ])
}
