variable "external_id" {
  description = "Shared secret for the SecurityAuditRole trust policy (confused-deputy defense)"
  type        = string
  sensitive   = true
}
