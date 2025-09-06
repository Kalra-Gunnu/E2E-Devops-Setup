resource "aws_ecr_repository" "repos" {
  for_each = toset(var.repositories)

  name                 = each.key
  image_tag_mutability = var.image_tag_mutability
  tags                 = var.tags
}

output "repo_urls" {
  value = { for k, r in aws_ecr_repository.repos : k => r.repository_url }
}