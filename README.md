# Cloud Security Portfolio

Hands-on cloud security engineering on AWS with Terraform — implementing the identity, network, logging, and incident-response patterns that real organizations rely on, and documenting the reasoning behind each decision.

## About

I'm Amir, and I'm building this portfolio to develop and demonstrate practical cloud security skills. For each project I design, implement, and **test** security controls as Infrastructure as Code, then write up the design trade-offs behind them. Every project stands on its own with working Terraform and a decisions document. This is a growing series — more projects are added as I complete them.

## Projects

| # | Project | What it demonstrates | Status |
|---|---------|----------------------|--------|
| 1 | [IAM Cross-Account Access](01-iam-cross-account-access/) | Multi-account trust, least-privilege roles, MFA & ExternalId conditions, tag-scoped permissions, assume-role | ✅ Complete |
| 2 | [VPC Infrastructure as Code](02-vpc-infrastructure-as-code/) | Network segmentation, public/private subnets, routing, tiered least-privilege security groups | ✅ Complete |
| 3 | CI/CD Security Pipeline | Shift-left security, policy as code, automated security testing | 📋 Planned |
| 4 | Cloud Security Audit | Compliance auditing (Prowler), risk prioritization, remediation | 📋 Planned |
| 5 | Centralized Logging | Log aggregation, immutability, incident response | 📋 Planned |
| 6 | Break-Glass Access | Emergency access procedures, governance, audit trails | 📋 Planned |
| 7 | Secrets Management | Credential hygiene, rotation, blast-radius reduction | 📋 Planned |
| 8 | Threat Modeling | STRIDE methodology, attack paths, control mapping | 📋 Planned |

## Tools & Focus

- **Cloud:** AWS (IAM, STS, EC2, CloudTrail, Organizations)
- **Infrastructure as Code:** Terraform
- **Security themes:** least privilege, identity & access management, detection & monitoring, defense in depth

## Attribution

The project briefs and learning roadmap are based on the [Cloud Security Projects](https://github.com/taimurijlal/CloudSecurityProjects) series by Taimur Ijlal (MIT License). All Terraform implementation, testing, and design decisions in this repository are my own work.
