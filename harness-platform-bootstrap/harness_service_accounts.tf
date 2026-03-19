# Account-level service account for the Tofu Deployer pipeline.
# Scoped at account level so it can manage orgs and projects across the platform.

resource "harness_platform_service_account" "tofu_deployer" {
  identifier  = "tofu_deployer"
  name        = "Tofu Deployer"
  email       = "tofu-deployer@service.harness.io"
  account_id  = var.harness_platform_account
  description = "Service account for OpenTofu pipeline deployments — manages orgs, projects, and resources via the tofu_deploy pipeline"
}

resource "harness_platform_apikey" "tofu_deployer" {
  depends_on = [harness_platform_service_account.tofu_deployer]

  identifier  = "tofu_deployer_apikey"
  name        = "Tofu Deployer API Key"
  parent_id   = harness_platform_service_account.tofu_deployer.identifier
  apikey_type = "SERVICE_ACCOUNT"
  account_id  = var.harness_platform_account

  lifecycle {
    ignore_changes = [default_time_to_expire_token]
  }
}

resource "harness_platform_token" "tofu_deployer" {
  depends_on = [harness_platform_apikey.tofu_deployer]

  identifier  = "tofu_deployer_token"
  name        = "Tofu Deployer Token"
  parent_id   = harness_platform_service_account.tofu_deployer.identifier
  apikey_type = "SERVICE_ACCOUNT"
  apikey_id   = harness_platform_apikey.tofu_deployer.identifier
  account_id  = var.harness_platform_account
}

# Account-level secret storing the SA token value.
# Referenced in pipelines as: <+secrets.getValue("account.harness_platform_api_key")>
resource "harness_platform_secret_text" "tofu_deployer_token" {
  depends_on = [harness_platform_token.tofu_deployer]

  identifier                = "harness_platform_api_key"
  name                      = "Harness Platform API Key"
  description               = "Auto-generated token for the Tofu Deployer service account"
  secret_manager_identifier = "harnessSecretManager"

  value_type = "Inline"
  value      = harness_platform_token.tofu_deployer.value
}

resource "harness_platform_role_assignments" "tofu_deployer_account_admin" {
  depends_on = [harness_platform_service_account.tofu_deployer]

  resource_group_identifier = "_all_resources_including_child_scopes"
  role_identifier           = "_account_admin"

  principal {
    identifier = harness_platform_service_account.tofu_deployer.id
    type       = "SERVICE_ACCOUNT"
  }

  managed = false
}
