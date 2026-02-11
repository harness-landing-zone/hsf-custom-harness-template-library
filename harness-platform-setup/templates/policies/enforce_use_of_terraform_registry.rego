package harness_iacm

# Helper to find ALL modules in the plan
module_calls[call] {
  walk(input.configuration.root_module, [p, v])
  p[count(p)-1] == "module_calls"
  mc := v[_]
  call := mc
}

deny[msg] {
  call := module_calls[_]

  # ALLOW local paths
  not startswith(call.source, "./")
  not startswith(call.source, "../")
  
  # ALLOW ONLY your specific Harness Registry
  not startswith(call.source, "app.harness.io/qIYsos1ZQO6fJMG1Ip6KJA")

  msg := sprintf("Module source %q is not allowed. You must use the Harness Registry for account qIYsos.", [call.source])
}