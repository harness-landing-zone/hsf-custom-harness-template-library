variable "harness_platform_url" {
  type        = string
  description = "[Optional] Harness Platform URL. Defaults to Harness SaaS."
  default     = "https://app.harness.io/gateway"
}

variable "harness_platform_account" {
  type        = string
  description = "[Required] Harness Platform Account ID."
}

variable "tags" {
  type        = map(any)
  description = "[Optional] Additional tags to apply to all resources."
  default     = {}
}

variable "organization_name" {
  type        = string
  description = "[Required] Organization folder/name to target. Used for org creation and for resolving project config."
  default     = "Platform Management"
}

variable "organization_id" {
  type        = string
  description = "[Optional] Explicit organization identifier override. If omitted, the deployment root resolves it from config.yaml or from the normalized organization name."
  default     = null
}

variable "project_name" {
  type        = string
  description = "[Optional] Project display name to create under the organization."
  default     = null
}

variable "project_id" {
  type        = string
  description = "[Optional] Explicit project identifier override. If omitted, the deployment root resolves it from config.yaml or from the normalized project name."
  default     = null
}

variable "create_organization" {
  type        = bool
  description = "[Optional] Set to true to deploy the organization module. This also creates any projects discovered in that org config."
  default     = false

  validation {
    condition     = !(var.create_organization && var.create_project)
    error_message = "create_organization and create_project are separate deployment modes. Use only one of them per run."
  }
}

variable "create_account" {
  type        = bool
  description = "[Optional] Set to true to deploy account-level resources through the harness-platform-setup module."
  default     = false
}

variable "create_project" {
  type        = bool
  description = "[Optional] Set to true to deploy only the project module against an existing organization."
  default     = false

  validation {
    condition     = !var.create_project || var.project_name != null
    error_message = "When create_project is true, project_name must be set."
  }
}

variable "git_connector_credentials" {
  type = map(object({
    http_credentials = optional(any, null)
    ssh_credentials  = optional(any, null)
    api_auth         = optional(any, null)
  }))
  sensitive   = true
  description = "[Optional] Credentials for git connectors keyed by connector identifier. Use terraform.tfvars (gitignored) instead of embedding credentials in YAML. Takes effect only when the connector YAML does not define the credential block."
  default     = {}
}

variable "configs_relative_path" {
  type        = string
  description = "Relative path to the platform-configs directory from this module. This is used to resolve the organization configuration files, independent of the current working directory."
  default     = "../platform-configs"
}
