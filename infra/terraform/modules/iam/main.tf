# Create IAM OIDC provider if not present
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

resource "aws_iam_openid_connect_provider" "oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc_cert.certificates[0].sha1_fingerprint]
  url             = replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")
}

data "tls_certificate" "oidc_cert" {
  url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

# Example: IAM role for External Secrets (read secrets from Secrets Manager)
resource "aws_iam_role" "external_secrets" {
  name = "${var.cluster_name}-external-secrets-role-${var.environment}"

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
          "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:${var.external_secrets_namespace}:${var.external_secrets_sa}"
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
        Resource = var.external_secrets_arn_wildcard ? "*" : var.external_secrets_resources
      },
      {
        Sid = "AllowKMSDecryptIfUsed",
        Effect = "Allow",
        Action = [
          "kms:Decrypt"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_external_secrets" {
  role       = aws_iam_role.external_secrets.name
  policy_arn = aws_iam_policy.external_secrets_policy.arn
}

output "external_secrets_role_arn" {
  value = aws_iam_role.external_secrets.arn
}
