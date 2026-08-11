output "security_audit_role_arn" {
  description = "ARN of the SecurityAuditRole"
  value       = module.iam.security_audit_role_arn
}

output "incident_response_role_arn" {
  description = "ARN of the IncidentResponseRole"
  value       = module.iam.incident_response_role_arn
}
