# AWS Connectors
variable "connector_name" {
  description = "Name of the connector."
  type        = string
}

variable "connector_identifier" {
  description = "Unique identifier of the connector."
  type        = string
  default     = null
  nullable    = true
}

variable "connector_description" {
  description = "Description of the resource."
  type        = string
  default     = null
  nullable    = true
}

variable "connector_tags" {
  description = "Tags to associate with the resource."
  type        = set(string)
  default     = []
}

variable "org_id" {
  description = "Unique identifier of the organization."
  type        = string
  default     = null
  nullable    = true
}

variable "project_id" {
  description = "Unique identifier of the project."
  type        = string
  default     = null
  nullable    = true
}

variable "execute_on_delegate" {
  description = "Execute on delegate or not."
  type        = bool
  default     = false
}

variable "force_delete" {
  description = "Enable this flag for force deletion of connector"
  type        = bool
  default     = false
}

# AWS Connetror Authentication Inputs
variable "aws_connector_inherit_from_delegate" {
  description = "Authentication using harness delegate."
  type = object({
    delegate_selectors = set(string)
    region             = optional(string)
  })
  default = null
}

variable "aws_connector_manual_authentication" {
  description = "Authentication using harness delegate."
  type = object({
    access_key_ref     = string
    secret_key_ref     = string
    delegate_selectors = set(string)
    region             = optional(string)
  })
  default = null
}

variable "aws_connector_irsa_authentication" {
  description = "IRSA authentication for AWS connector."
  type = object({
    delegate_selectors = set(string)
    region             = optional(string)
  })
  default = null
}

variable "aws_connector_oidc_authentication" {
  description = "OIDC authentication for AWS connector."
  type = object({
    iam_role_arn       = string
    delegate_selectors = optional(set(string), [])
    region             = optional(string)
  })
  default = null

  validation {
    condition     = var.aws_connector_oidc_authentication == null || trimspace(var.aws_connector_oidc_authentication.iam_role_arn) != ""
    error_message = "aws_connector_oidc_authentication.iam_role_arn must be set when OIDC authentication is used."
  }
}

variable "aws_connector_cross_account_access" {
  description = "Use cross account access for delegation."
  type = object({
    role_arn    = string
    external_id = optional(string, "")
  })
  default = null
}

variable "aws_connector_equal_jitter_backoff_strategy" {
  description = "Equal jitter backoff strategy."
  type = object({
    base_delay       = optional(number, null)
    max_backoff_time = optional(number, null)
    retry_count      = optional(number, null)
  })
  default = null
}

variable "aws_connector_fixed_delay_backoff_strategy" {
  description = "Fixed delay backoff strategy."
  type = object({
    fixed_backoff = optional(number, null)
    retry_count   = optional(number, null)
  })
  default = null
}

variable "aws_connector_full_jitter_backoff_strategy" {
  description = "Full jitter backoff strategy."
  type = object({
    base_delay       = optional(number, null)
    max_backoff_time = optional(number, null)
    retry_count      = optional(number, null)
  })
  default = null
}
