output "security_audit_role_arn" {
  description = "ARN of the SecurityAuditRole"
  value       = aws_iam_role.security_audit.arn
}

output "incident_response_role_arn" {
  description = "ARN of the IncidentResponseRole"
  value       = aws_iam_role.incident_response.arn
}
