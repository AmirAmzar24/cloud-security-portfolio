variable "external_id" {
  description = "Shared secret for the SecurityAuditRole trust policy (confused-deputy defense)"
  type        = string
  sensitive   = true
}

variable "trusted_principal_arn" {
  description = "ARN of the principal allowed to assume these roles"
  type        = string
}
