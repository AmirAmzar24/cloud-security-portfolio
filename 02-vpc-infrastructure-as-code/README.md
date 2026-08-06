# Project 2: VPC Infrastructure as Code

A secure, segmented AWS VPC built with Terraform — demonstrating public/private subnet isolation, routing, and least-privilege security groups, with security as a first-class concern.

> **Design decisions & reasoning:** see [DESIGN.md](DESIGN.md) for the full write-up — why resources go in private subnets, what traffic is allowed, how security groups and NACLs complement each other, where logging/inspection would live, how the design reduces attack surface, and how it supports future growth.

## What This Demonstrates

- **Network segmentation** — a public tier (internet-facing) and a private tier (isolated), so critical resources are unreachable from the internet.
- **Routing as the public/private boundary** — a subnet is "public" only because its route table sends `0.0.0.0/0` to an Internet Gateway; the private subnet has no such route.
- **Least-privilege security groups** — a tiered, identity-based firewall chain (`web_sg → db_sg`) instead of open CIDR rules.
- **Least-privilege egress** — the database's outbound access is scoped (not allow-all), limiting exfiltration if compromised.
- **Cost-conscious IaC** — the NAT Gateway pattern is written and `terraform plan`-validated, but left un-applied to avoid cost.

## Architecture

A two-tier VPC (`10.0.0.0/16`):

| Component | Value | Purpose |
|-----------|-------|---------|
| **Public subnet** | `10.0.1.0/24` | Internet-facing tier (e.g., web server / load balancer) |
| **Private subnet** | `10.0.2.0/24` | Isolated tier (e.g., database) — no internet route |
| **Internet Gateway** | attached to VPC | The door between the VPC and the internet |
| **Public route table** | `0.0.0.0/0 → IGW` | Makes the public subnet public (associated to it) |
| **`web_sg`** | ingress 443 from `0.0.0.0/0`; all egress | Web tier firewall |
| **`db_sg`** | ingress 3306 from `web_sg` only; egress scoped to 443 | Database firewall (identity-based, least privilege) |

**Traffic flow:**
```
Internet → IGW → Public route table → web_sg (443) → web tier
                                   web tier → db_sg (3306) → database (private subnet)
```

### Scope & honest notes
This is a focused, cost-free lab demonstrating the core patterns. Deliberately *not* deployed (but discussed in [DESIGN.md](DESIGN.md) as design knowledge):
- **NAT Gateway** — written and `plan`-validated, but commented out (paid resource). The private subnet is currently fully isolated.
- **Single AZ** — both subnets are in `ap-southeast-1a`; production would span multiple AZs.
- **NACLs** — subnets use the default (allow-all) NACL; all filtering is done by security groups.
- **VPC Flow Logs / inspection** — not implemented here (Flow Logs are covered in Project 5).

## Tech

- **AWS:** VPC, Subnets, Internet Gateway, Route Tables, Security Groups
- **Terraform:** `>= 1.0`, AWS provider `~> 5.0`
- **Region:** `ap-southeast-1`

## How to Run

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

There are no secrets or variables to supply for this project. All deployed resources are **free** (the only paid resource, the NAT Gateway, is intentionally left commented out).

To tear down:
```bash
terraform destroy
```

## Attribution

Project brief from Taimur Ijlal's [Cloud Security Projects](https://github.com/taimurijlal/CloudSecurityProjects) (MIT License). Terraform implementation, testing, and [design decisions](DESIGN.md) are my own work.
