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
  description = "[Required] New Organization Name"
  default     = "Harness Management"
}
