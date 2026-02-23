output "connector_id" {
  description = "Harness connector ID."
  value       = harness_platform_connector_aws.aws.id
}

output "connector_identifier" {
  description = "Harness connector identifier."
  value       = harness_platform_connector_aws.aws.identifier
}

output "connector_name" {
  description = "Harness connector display name."
  value       = harness_platform_connector_aws.aws.name
}
