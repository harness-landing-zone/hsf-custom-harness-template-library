module "platform_management" {
  source = "../harness-organization"

  organization_name        = var.organization_name
  harness_platform_account = var.harness_platform_account
  harness_platform_url     = var.harness_platform_url
  tags                     = var.tags

  # Pass the bootstrap directory as the config root so the module reads
  # organizations/ from this folder instead of an external platform-configs repo.
  configs_relative_path = "../harness-platform-bootstrap"
  git_connector_credentials = var.git_connector_credentials
  # PEM files for file-type secrets live in harness-platform-bootstrap/pem/ (gitignored).
  pem_path = "${path.module}/pem"
}

output "platform_configs_dir" {
  value = module.platform_management.platform_configs_dir
}

output "source_directory" {
  value = module.platform_management.source_directory
}

output "org_directory" {
  value = module.platform_management.org_directory
}
  