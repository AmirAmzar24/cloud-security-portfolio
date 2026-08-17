# Project 2: VPC Infrastructure as Code

A secure, segmented AWS VPC built with Terraform — demonstrating public/private subnet isolation, routing, and least-privilege security groups, with security as a first-class concern.

> **Design decisions & reasoning:** see [DESIGN.md](DESIGN.md) for the full write-up — why resources go in private subnets, what traffic is allowed, how security groups and NACLs complement each other, where logging/inspection would live, how the design reduces attack surface, and how it supports future growth.

## What This Demonstrates

- **Network segmentation** — a public tier (internet-facing) and a private tier (isolated), so critical resources are unreachable from the internet.
- **Routing as the public/private boundary** — a subnet is "public" only because its route table sends `0.0.0.0/0` to an Internet Gateway; the private subnet has no such route.
- **Least-privilege security groups** — a tiered, identity-based firewall chain (`web_sg → db_sg`) instead of open CIDR rules.
- **Least-privilege egress** — the database's outbound access is scoped (not allow-all), limiting exfiltration if compromised.
- **Multi-AZ high availability** — public and private subnets replicated across two Availability Zones (built with `for_each` over an AZ→CIDR map).
- **Layered firewalls** — a subnet-level **NACL** (stateless) on the public tier, on top of the instance-level security groups (stateful) — defense in depth at two levels.
- **Private AWS access without NAT** — an **S3 Gateway VPC Endpoint** lets the private subnet reach S3 over AWS's private network, with no NAT Gateway (and no cost).
- **Cost-conscious IaC** — the NAT Gateway pattern is written and `terraform plan`-validated, but left un-applied to avoid cost.
- **Production-shaped Terraform** — packaged as a reusable module, parameterized with variables, with encrypted/locked S3 remote state.

## Architecture

A two-tier VPC (`10.0.0.0/16`), spread across two Availability Zones:

| Component | Value | Purpose |
|-----------|-------|---------|
| **Public subnets** | `10.0.1.0/24` (AZ-a), `10.0.3.0/24` (AZ-b) | Internet-facing tier, across 2 AZs |
| **Private subnets** | `10.0.2.0/24` (AZ-a), `10.0.4.0/24` (AZ-b) | Isolated tier (e.g., database), across 2 AZs |
| **Internet Gateway** | attached to VPC | The door between the VPC and the internet |
| **Public route table** | `0.0.0.0/0 → IGW` | Makes the public subnets public |
| **Private route table** | S3 prefix-list → endpoint (no internet route) | Keeps the private subnets isolated; only S3 is reachable, privately |
| **S3 Gateway Endpoint** | attached to the private route table | Private S3 access with no NAT Gateway |
| **Public NACL** | 443 in + ephemeral return traffic; all out | Subnet-level stateless firewall on both public subnets |
| **`web_sg`** | ingress 443 from `0.0.0.0/0`; all egress | Web tier firewall |
| **`db_sg`** | ingress 3306 from `web_sg` only; egress scoped to 443 | Database firewall (identity-based, least privilege) |

**Traffic flow:**
```
Internet → IGW → Public route table → web_sg (443) → web tier
                                   web tier → db_sg (3306) → database (private subnet)
```

### Scope & honest notes
This is a focused, cost-free lab. What's deliberately *not* deployed (discussed in [DESIGN.md](DESIGN.md) as design knowledge):
- **NAT Gateway** — written and `plan`-validated, but commented out (the one paid resource). The private subnets reach S3 via the gateway endpoint instead, and have no general internet egress.
- **VPC Flow Logs / inspection** — not implemented here (Flow Logs are covered in Project 5).
- **No EC2 instances** — the network is a secure, empty scaffold; the security groups exist but aren't attached to running instances (which is why it stays at $0).

## Tech

- **AWS:** VPC, multi-AZ Subnets, Internet Gateway, Route Tables, Security Groups, Network ACL, S3 Gateway VPC Endpoint
- **Terraform:** `>= 1.0`, AWS provider `~> 5.0` (reusable module, `for_each`, S3 remote state)
- **Region:** `ap-southeast-1`

## How to Run

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

There are no secrets to supply, and all variables have sensible defaults. All deployed resources are **free** (the only paid resource, the NAT Gateway, is intentionally left commented out).

To tear down:
```bash
terraform destroy
```

## Attribution

Project brief from Taimur Ijlal's [Cloud Security Projects](https://github.com/taimurijlal/CloudSecurityProjects) (MIT License). Terraform implementation, testing, and [design decisions](DESIGN.md) are my own work.
