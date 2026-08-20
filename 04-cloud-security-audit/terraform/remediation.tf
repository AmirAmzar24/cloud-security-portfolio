# -- IAM Account Password Policy --
resource "aws_iam_account_password_policy" "strict_iam_pwd_policy" {
  minimum_password_length        = 14
  require_uppercase_characters   = true
  require_lowercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  password_reuse_prevention      = 24
  max_password_age               = 90
  allow_users_to_change_password = true
}

# -- Account-level S3 Block Public Access --
resource "aws_s3_account_public_access_block" "global_public_access_block" {
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# -- IAM Access Analyzer -- 
resource "aws_accessanalyzer_analyzer" "access_analyzer" {
  analyzer_name = "account-access-analyzer"
  type          = "ACCOUNT"
}