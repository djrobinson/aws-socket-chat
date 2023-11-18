output "cognito_client_ids" {
  description = "cognito_client_ids"
  value       = module.aws_cognito.client_ids
}

output "cognito_client_stuff" {
  description = "cognito_client_stuff"
  sensitive = true
  value       = module.aws_cognito.client_secrets
}

output "cognito_issuer" {
  description = "cognito_issuer"
  value       = module.aws_cognito.endpoint
}
