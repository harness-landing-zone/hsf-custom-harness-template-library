module "platform_management" {
  source = "../harness-organization"

  organization_name        = var.organization_name
  harness_platform_account = var.harness_platform_account
  harness_platform_url     = var.harness_platform_url
  tags                     = var.tags

  # Pass the bootstrap directory as the config root so the module reads
  # organizations/ from this folder instead of an external platform-configs repo.
  configs_relative_path = path.module

  # PEM files for file-type secrets live in harness-platform-bootstrap/pem/ (gitignored).
  pem_path = "${path.module}/pem"
}
