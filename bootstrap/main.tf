# -- S3 Bucket --
resource "aws_s3_bucket" "tf_state" {
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
    bucket = aws_s3_bucket.tf_state.id
    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
}

