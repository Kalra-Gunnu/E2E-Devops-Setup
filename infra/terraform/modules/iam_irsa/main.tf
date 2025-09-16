

resource "aws_iam_openid_connect_provider" "oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [var.oidc_provider_thumbprint] # Use a new variable
  url             = var.oidc_provider_url        # Use a new variable
}

resource "aws_iam_role" "external_secrets" {
  # ... (name, etc.)
  name = "${var.cluster_name}-external-secrets-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.oidc.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          # Use the variable directly
          "${replace(var.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:${var.external_secrets_namespace}:${var.external_secrets_sa}"
        }
      }
    }]
  })
  
  tags = var.tags
}

# Attach policy with least privilege to read specific secrets (example)
resource "aws_iam_policy" "external_secrets_policy" {
  name   = "${var.cluster_name}-external-secrets-policy-${var.environment}"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "AllowGetSecretValue"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets"
        ]
        Resource = var.external_secrets_arn_wildcard ? ["*"] : var.external_secrets_resources
      },
      {
        Sid = "AllowKMSDecryptForSecretsManager",
        Effect = "Allow",
        Action = [
          "kms:Decrypt"
        ],
        Resource = [
          "arn:aws:kms:${var.aws_region}:aws:alias/aws/secretsmanager"
        ],
        Condition = {
          StringEquals = {
            "kms:ViaService": "secretsmanager.${var.aws_region}.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_external_secrets" {
  role       = aws_iam_role.external_secrets.name
  policy_arn = aws_iam_policy.external_secrets_policy.arn
}
