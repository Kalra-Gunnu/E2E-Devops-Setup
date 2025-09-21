output "tfstate_bucket_name" {
  description = "Name of the S3 bucket used for Terraform state"
  value       = aws_s3_bucket.tfstate.id
}

output "tfstate_bucket_arn" {
  description = "ARN of the S3 bucket used for Terraform state"
  value       = aws_s3_bucket.tfstate.arn
}

output "tfstate_lock_table_name" {
  description = "Name of the DynamoDB table used for state locking"
  value       = aws_dynamodb_table.tf_locks.id
}

output "tfstate_lock_table_arn" {
  description = "ARN of the DynamoDB table used for state locking"
  value       = aws_dynamodb_table.tf_locks.arn
}