// ==============================================================================
// terraform/aws の tfvars に転記する値
// ==============================================================================

output "azure_tenant_id" {
  description = "→ AWS の azure_tenant_id"
  value       = data.azurerm_client_config.current.tenant_id
}

output "function_principal_id" {
  description = "→ AWS の azure_function_principal_id (トークンの sub クレームと一致)"
  value       = module.function_app.principal_id
}

output "aws_oidc_audience" {
  description = "→ AWS の azure_oidc_audience (entra_requested_token_version に応じた形式)"
  value       = module.entra_app.aws_oidc_audience
}

output "aws_oidc_audience_v1" {
  description = "v1 トークンの場合の aud (参考)"
  value       = module.entra_app.aws_oidc_audience_v1
}

output "aws_oidc_audience_v2" {
  description = "v2 トークンの場合の aud (参考)"
  value       = module.entra_app.aws_oidc_audience_v2
}

output "azure_token_scope" {
  description = "Function がマネージドID にトークンを要求するときのスコープ"
  value       = module.entra_app.token_scope
}

// ==============================================================================
// 動作確認・デプロイに使う値
// ==============================================================================

output "function_app_name" {
  description = "Function App 名 (zip デプロイ先)"
  value       = module.function_app.name
}

output "function_app_hostname" {
  description = "Function App のホスト名"
  value       = module.function_app.default_hostname
}

output "function_app_base_url" {
  description = "エンドポイントのベース URL"
  value       = module.function_app.base_url
}

output "resource_group_name" {
  description = "リソースグループ名"
  value       = azurerm_resource_group.main.name
}

output "application_insights_name" {
  description = "Application Insights のリソース名 (ログ照会に使う)"
  value       = module.function_app.application_insights_name
}
