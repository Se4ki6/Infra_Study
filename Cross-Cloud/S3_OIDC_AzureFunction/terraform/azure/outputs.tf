output "entra_app_client_id" {
  value = module.entra_app.client_id
}

output "entra_app_identifier_uri" {
  description = "terraform/aws の azure_oidc_audience（v1トークン運用時）に渡す値"
  value       = module.entra_app.identifier_uri
}

output "entra_app_token_scope" {
  value = module.entra_app.token_scope
}

output "function_app_name" {
  value = module.function_app.function_app_name
}

output "function_app_default_hostname" {
  value = module.function_app.function_app_default_hostname
}

output "function_app_principal_id" {
  description = "terraform/aws の azure_function_principal_id に渡す値"
  value       = module.function_app.principal_id
}
