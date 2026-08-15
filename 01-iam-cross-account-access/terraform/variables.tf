variable "external_id" {
  description = "Shared secret for the SecurityAuditRole trust policy (confused-deputy defense)"
  type        = string
  sensitive   = true
}

variable "trusted_principal_arn" {
  description = "ARN of the principal allowed to assume the roles"
  type        = string
  default     = "arn:aws:iam::640168411629:user/admin-amir"
}

variable "github_repo" {
  description = "GitHub repo allowed to assume the DeploymentRole"
  type        = string
  default     = "AmirAmzar24/cloud-security-portfolio"
}

