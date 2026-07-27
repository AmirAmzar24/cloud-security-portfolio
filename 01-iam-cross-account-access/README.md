# Project 1: IAM Cross-Account Access

Cross-account IAM roles on AWS, built with Terraform — demonstrating secure role assumption, least-privilege permissions, and condition-based trust policies (MFA, ExternalId, resource tags).

> **Design decisions & reasoning:** see [DESIGN.md](DESIGN.md) for the full write-up — why role assumption over long-lived credentials, how this scales to 100 accounts, over-privilege risk, misuse detection, and what happens if the hub is compromised.

## What This Demonstrates

- **Role assumption over long-lived credentials** — short-lived, auditable, gate-able access instead of static keys.
- **Trust policies with conditions** — the "who may assume this role" gate, hardened with:
  - **ExternalId** (confused-deputy defense) on `SecurityAuditRole`
  - **MFA required** (`aws:MultiFactorAuthPresent`) on `IncidentResponseRole`
- **Least-privilege permission policies** — custom, hand-scoped policies instead of broad AWS-managed ones.
- **Tag-scoped write permissions** — incident-response containment actions restricted to resources tagged `Quarantine=true`.
- **Secret handling** — the ExternalId is a Terraform variable sourced from a gitignored `terraform.tfvars`, never committed (see `terraform.tfvars.example` for the shape).

## Architecture

Two roles, each protected by two gates — a **trust policy** (who can assume it) and a **permission policy** (what it can do):

| Role | Trust (who can assume) | Permissions (what it can do) |
|------|------------------------|------------------------------|
| **SecurityAuditRole** | `admin-amir` + correct **ExternalId** | Read-only EC2 metadata: `DescribeInstances`, `DescribeVpcs`, `DescribeVolumes` |
| **IncidentResponseRole** | `admin-amir` + **MFA** | Read: `ec2:Describe*`. Contain (tag-gated): `StopInstances`, `CreateSnapshot`, `RevokeSecurityGroupEgress` |

`IncidentResponseRole` deliberately **excludes** `ec2:TerminateInstances` — containment should be reversible and must not destroy forensic evidence (stopping an instance is recoverable; terminating is not).

> **Note on single-account setup:** cross-account access normally spans two or more accounts. I implemented it within a single account (roles trusted by an IAM user in the same account); the trust/permission model is identical, and [DESIGN.md](DESIGN.md) covers how it scales to a true multi-account hub-and-spoke design.

## Tech

- **AWS:** IAM, STS, EC2
- **Terraform:** `>= 1.0`, AWS provider `~> 5.0`
- **Region:** `ap-southeast-1`

## How to Run

1. **Prerequisites:** AWS CLI configured with an admin identity, Terraform installed.
2. **Supply the secret** — copy the example tfvars and set your own ExternalId:
   ```bash
   cp terraform/terraform.tfvars.example terraform/terraform.tfvars
   # then edit terraform.tfvars → external_id = "your-secret"
   ```
3. **Deploy:**
   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```
4. **Tear down when finished:**
   ```bash
   terraform destroy
   ```

## Verifying the Controls

**ExternalId gate (`SecurityAuditRole`):**
```bash
# Denied — no ExternalId supplied:
aws sts assume-role --role-arn <SecurityAuditRole-ARN> --role-session-name test
# Succeeds — with the correct ExternalId:
aws sts assume-role --role-arn <SecurityAuditRole-ARN> --role-session-name test --external-id <your-secret>
```

**MFA gate (`IncidentResponseRole`):** using a named CLI profile with `role_arn` + `mfa_serial`, assuming the role without MFA is denied at the `AssumeRole` step; supplying a valid MFA code lets it succeed.

**Least privilege:** while assumed as `SecurityAuditRole`, a granted call (`aws ec2 describe-instances`) succeeds, while a non-granted call (`aws s3 ls`) returns `AccessDenied`.

## Attribution

Project brief from Taimur Ijlal's [Cloud Security Projects](https://github.com/taimurijlal/CloudSecurityProjects) (MIT License). Terraform implementation, testing, and [design decisions](DESIGN.md) are my own work.
