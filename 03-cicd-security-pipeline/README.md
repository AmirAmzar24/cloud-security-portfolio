# Project 3: CI/CD Security Pipeline

A GitHub Actions pipeline that automatically scans this portfolio's Terraform on every push and pull request — shift-left security as code, blocking insecure infrastructure before it can merge.

> **Design decisions & reasoning:** see [DESIGN.md](DESIGN.md) — what checks are included, when to block vs. warn, handling "too strict" checks and false positives, regulated environments, and balancing security with developer productivity.

## What This Demonstrates

- **Shift-left / DevSecOps** — security runs automatically on every commit, catching issues early (cheap) instead of after deploy (catastrophic).
- **Policy as code** — Checkov enforces hundreds of security rules on the Terraform automatically, with no human checklist.
- **Secret scanning** — Gitleaks catches credentials before they land in the repo.
- **Zero stored keys (OIDC)** — the pipeline authenticates to AWS via GitHub OIDC federation; no long-lived AWS keys are stored anywhere.
- **Drift detection** — a read-only `terraform plan` validates the live infrastructure against the code.
- **Security gating** — the plan job only runs (and only touches AWS) *after* the security scan passes.
- **A demonstrated block** — a pull request that opened SSH to the internet was caught and blocked (see below).

## Pipeline Architecture

The workflow lives at the repo root (`.github/workflows/security-scan.yml`) and scans the Terraform across all projects. It runs two jobs:

```
on: push / pull_request
│
├─ Job 1: iac-scan   (the gate — no AWS access)
│    ├─ Gitleaks              → secret scanning (full history)
│    ├─ terraform fmt -check  → formatting / consistency gate
│    └─ Checkov               → IaC security scan (enforcing: blocks on any finding)
│
└─ Job 2: terraform-plan   (needs: iac-scan — only runs if the gate passes)
     ├─ Configure AWS via OIDC     → assume DeploymentRole, zero stored keys
     ├─ terraform validate         → config validity
     └─ terraform plan -lock=false → drift detection (read-only)
```

Because `terraform-plan` **needs** `iac-scan`, no AWS credentials are issued and no plan runs until the security scan passes — so insecure code never reaches AWS.

## Security Gate in Action (Blocked PR)

To prove the gate works, I opened a pull request with a security group that exposed **SSH (port 22) to `0.0.0.0/0`**. Checkov flagged it (`CKV_AWS_24`), the `iac-scan` job **failed**, and the merge was **blocked** — the insecure code never reached `main`. The closed PR remains in the repo's history as evidence.

## Handling Findings (Exceptions)

The scan found real issues across the portfolio's Terraform. I triaged them into three buckets:
- **Fix** — e.g. added security-group rule descriptions, locked down the VPC default security group.
- **Accept with documented justification** — `#checkov:skip=<ID>:<reason>` for by-design findings (like public subnets assigning public IPs, or unattached security groups in an empty lab).
- **False positive** — e.g. `CKV2_AWS_1`, where the NACL *was* attached via the inline `subnet_ids` argument (Checkov only detects a separate association resource).

Every suppression carries a reason. See [DESIGN.md](DESIGN.md) for the exception-governance model.

## Tools

- **GitHub Actions** — CI/CD runner
- **Checkov** — IaC security scanning (policy as code)
- **Gitleaks** — secret scanning
- **Terraform** — `fmt`, `validate`, `plan`
- **AWS IAM OIDC** — zero-key federated authentication (the DeploymentRole is defined in Project 1)

## How It Runs

The pipeline runs **automatically** on every push and pull request — there's no manual step. Results appear in the repository's **Actions** tab. The OIDC DeploymentRole it assumes is defined in [Project 1's Terraform](../01-iam-cross-account-access/terraform/deployment.tf).

## Attribution

Project brief from Taimur Ijlal's [Cloud Security Projects](https://github.com/taimurijlal/CloudSecurityProjects) (MIT License). Pipeline implementation, finding triage, and [design decisions](DESIGN.md) are my own work.
