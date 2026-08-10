# providers.tf — tells Terraform WHICH cloud/plugins it needs and HOW to connect.

terraform {
  # Refuse to run on an ancient Terraform that might not understand our syntax.
  required_version = ">= 1.0"

  # Declare the providers (plugins) this project uses. Here: just AWS.
  required_providers {
    aws = {
      source  = "hashicorp/aws" # official AWS provider from the Terraform Registry
      version = "~> 5.0"        # any 5.x version; won't silently jump to 6.x and break us
    }
  }
}

# Configure the AWS provider. It automatically uses the credentials you set
# with `aws configure` (from ~/.aws/credentials) — no keys in this file. Good.
provider "aws" {
  region = "ap-southeast-1" # matches your CLI default region (Singapore)
}
