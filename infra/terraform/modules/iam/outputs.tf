output "external_secrets_role_arn" { value = aws_iam_role.external_secrets.arn }
output "oidc_provider" { value = aws_iam_openid_connect_provider.oidc.arn }
