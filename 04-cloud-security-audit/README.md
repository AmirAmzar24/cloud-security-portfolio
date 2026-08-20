# Project 4: Cloud Security Audit

An automated security audit of my AWS account using Prowler, with risk-based triage and infrastructure-as-code remediation. The value isn't in running the scanner, it's in interpreting the findings: separating real risks from noise, fixing what matters, and documenting what I accept and why.

> **Design decisions & reasoning:** see [DESIGN.md](DESIGN.md) for the full write-up — how I tell signal from noise, which findings actually matter in this context, what I accept as risk and why, how I prioritize remediation over time, what compensating controls justify an accepted risk, and how I'd present all of this to non-technical leadership.

## What This Demonstrates

- **The auditor's perspective** — assessing a whole account against an industry benchmark (CIS), not just building one control.
- **Risk-based triage** — turning 89 raw failures into a sorted list (fix / accept / defer / not-applicable), because a scanner has no idea what an account is *for*.
- **Severity is not priority** — judging findings by real risk in context, e.g. fixing a High before accepting a Critical that's by design.
- **Remediation as code** — every fix written in Terraform, applied, then re-scanned to prove it worked, rather than clicked in the console.
- **Documented accepted risk** — findings I consciously accept, each with reasoning and a compensating control, so an acceptance is a decision and not negligence.

## Audit Results

Scan scope: account `640168411629`, region `ap-southeast-1`, run read-only as my admin identity (Prowler only makes `Describe`/`List`/`Get` calls).

| | Baseline | After remediation |
|---|---|---|
| **PASS** | 72 | 83 |
| **FAIL** | 89 | 80 |
| Manual | 6 | 6 |

**10 findings remediated as code and verified green on re-scan.** The remaining failures are accepted-with-justification, deferred to a later project, or not applicable to a single standalone account (see [DESIGN.md](DESIGN.md)).

## Remediations

All fixes are Terraform. The account-level ones live in [terraform/](terraform/); the state-bucket policy lives in [../bootstrap/](../bootstrap/), where the bucket is defined.

| Fix | Findings closed | Why it mattered |
|-----|-----------------|-----------------|
| IAM account password policy | 7 | No password policy existed; weak passwords are an easy way in |
| S3 account-level Block Public Access | 1 (High) | Backstop so no future bucket can be made public by accident |
| IAM Access Analyzer | 1 | Continuously flags any resource shared outside the account |
| State bucket: deny non-HTTPS | 1 | Data could otherwise be read over an unencrypted connection |

## Accepted Risks (summary)

Some findings I accept on purpose, each backed by reasoning and a compensating control (full detail in [DESIGN.md](DESIGN.md)):

- **SSE-S3 instead of KMS** on the state bucket — data is still encrypted at rest; a customer-managed key is overhead I don't need here.
- **No MFA-delete** — can't be set via Terraform; bucket versioning already protects against deletion.
- **Unused security groups** — an empty network scaffold with no EC2 by design; the SGs are still locked down.
- **Default VPC / default NACLs** — AWS-created and unused; in a real org the fix is deleting the default VPC.
- **Organizations / SCP findings** — not applicable to a single standalone account.

## Tools

- **Prowler** — open-source AWS security assessment (CIS and other frameworks)
- **Terraform** — infrastructure-as-code remediation (`>= 1.0`, AWS provider `~> 5.0`, S3 remote state)
- **AWS:** IAM, S3, IAM Access Analyzer
- **Region:** `ap-southeast-1`

## How to Run

**1. Run the audit** (read-only, free):
```bash
prowler aws --region ap-southeast-1
```
Reports are written to `output/` (HTML, CSV, JSON).

**2. Apply the remediations:**
```bash
cd terraform
terraform init
terraform plan
terraform apply
```
(The state-bucket HTTPS policy is applied separately from `../bootstrap/`.)

**3. Re-scan to verify** the targeted findings have flipped to PASS:
```bash
prowler aws --region ap-southeast-1 --service iam s3 accessanalyzer
```

## Attribution

Project brief from Taimur Ijlal's [Cloud Security Projects](https://github.com/taimurijlal/CloudSecurityProjects) (MIT License). The audit, finding triage, remediation, and [design decisions](DESIGN.md) are my own work.