output "s3_bucket_name" {
  value = module.s3_bucket.bucket_id
}

output "s3_bucket_arn" {
  value = module.s3_bucket.bucket_arn
}

output "oidc_provider_arn" {
  value = module.sts_oidc_flow.oidc_provider_arn
}

output "web_identity_role_arn" {
  description = "terraform/azure の aws_web_identity_role_arn に渡す値"
  value       = module.sts_oidc_flow.role_arn
}
