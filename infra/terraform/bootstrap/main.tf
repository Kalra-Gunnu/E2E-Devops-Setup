provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile != "" ? var.aws_profile : null
}

# Resource for the S3 bucket itself
resource "aws_s3_bucket" "tfstate" {
  bucket = var.tfstate_bucket

  # The 'versioning' and 'server_side_encryption_configuration' blocks are correct and up-to-date.
  lifecycle {
    prevent_destroy = true
  }
}

# New resource to enable versioning on the bucket
resource "aws_s3_bucket_versioning" "tfstate_versioning" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

# New resource to configure server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate_encryption" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# New resource to block public access
resource "aws_s3_bucket_public_access_block" "tfstate_public_access" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# New resource to control bucket ownership and disable ACLs (recommended)
resource "aws_s3_bucket_ownership_controls" "tfstate_ownership" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# The 'acl' argument is no longer needed with 'BucketOwnerEnforced'
resource "aws_s3_bucket_acl" "tfstate_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.tfstate_ownership]
  bucket     = aws_s3_bucket.tfstate.id
  acl        = "private"
}

resource "aws_dynamodb_table" "tf_locks" {
  name         = var.tfstate_lock_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(var.tags, { Name = var.tfstate_lock_table })
}
