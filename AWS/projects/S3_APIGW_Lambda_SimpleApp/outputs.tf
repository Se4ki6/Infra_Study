output "api_endpoint" {
  description = "API Gateway Endpoint URL"
  value       = "${aws_api_gateway_stage.dev.invoke_url}/hello"
}

output "website_endpoint" {
  description = "S3 Website URL"
  value       = aws_s3_bucket_website_configuration.hosting.website_endpoint
}
