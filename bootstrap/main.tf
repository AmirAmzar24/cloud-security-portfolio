# -- S3 Bucket --
resource "aws_s3_bucket" "tf_state" {
  #checkov:skip=CKV_AWS_144:Cross-region replication unnecessary for a single-user lab state bucket
  #checkov:skip=CKV2_AWS_62:Event notifications not needed for state bucket
  #checkov:skip=CKV2_AWS_61:Lifecycle configuration not required here
  #checkov:skip=CKV_AWS_18:Access logging omitted for a solo lab state bucket
  #checkov:skip=CKV_AWS_145:AES256 (SSE-S3) encryption is sufficient here; KMS CMK not required
  bucket = "amir-cloudsecproject-tfstate-640168411629"
}

# -- Versioning -- 
resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# -- Encryption at Rest --
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# -- Block Public Access == 
resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -- IAM Policy Doc -- 
data "aws_iam_policy_document" "tf_state" {
  statement {
    effect  = "Deny"
    actions = ["s3:*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    resources = [aws_s3_bucket.tf_state.arn, "${aws_s3_bucket.tf_state.arn}/*"]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

# -- S3 Bucket Policy -- 
resource "aws_s3_bucket_policy" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  policy = data.aws_iam_policy_document.tf_state.json
}

