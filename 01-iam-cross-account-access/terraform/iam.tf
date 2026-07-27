# -- SecurityAuditRole --
data "aws_iam_policy_document" "audit_readonly" {
    statement { 
        effect = "Allow"
        actions = ["ec2:DescribeInstances", "ec2:DescribeVpcs", "ec2:DescribeVolumes"]
        resources = ["*"]
    }
}

resource "aws_iam_policy" "audit_readonly" {
    name = "SecurityAuditReadOnly"
    policy = data.aws_iam_policy_document.audit_readonly.json
}

resource "aws_iam_role" "security_audit" {
    name = "SecurityAuditRole"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Principal = { AWS = "arn:aws:iam::640168411629:user/admin-amir"}
                Action = "sts:AssumeRole"
                Condition = {
                    StringEquals = {
                        "sts:ExternalId" = var.external_id
                    }
                }
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "audit_attach" {
    role = aws_iam_role.security_audit.name
    policy_arn = aws_iam_policy.audit_readonly.arn
}

# -- IncidentResponseRole --
data "aws_iam_policy_document" "incident_response" {
    statement {
        sid = "ReadInvestigate"
        effect = "Allow"
        actions = ["ec2:Describe*"]
        resources = ["*"]
    }
    statement {
        sid = "ContainmentWrites"
        effect = "Allow"
        actions = ["ec2:RevokeSecurityGroupEgress", "ec2:CreateSnapshot", "ec2:StopInstances"]
        resources = ["*"]
        condition {
            test = "StringEquals"
            variable = "aws:ResourceTag/Quarantine"
            values = ["true"]
        }
    }
}

resource "aws_iam_policy" "incident_response" {
    name = "IncidentResponseActions"
    policy = data.aws_iam_policy_document.incident_response.json
}

resource "aws_iam_role" "incident_response" {
    name = "IncidentResponseRole"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Principal = { AWS = "arn:aws:iam::640168411629:user/admin-amir"}
                Action = "sts:AssumeRole"
                Condition = {
                    Bool = {
                        "aws:MultiFactorAuthPresent" = "true"
                    }
                }
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "incident_response_attach" {
    role = aws_iam_role.incident_response.name
    policy_arn = aws_iam_policy.incident_response.arn
}