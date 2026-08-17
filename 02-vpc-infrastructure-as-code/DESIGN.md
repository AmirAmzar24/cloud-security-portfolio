# Project 2: VPC Infrastructure as Code — Design Decisions

## 1. Why are certain resources in private subnets?

Critical resources like databases are placed in private subnets for security reasons. Resources in a private subnet are unreachable from the internet because there is no route to them. So when attackers run a port scan, for example, they can't even see the resource — which means there's no way to attempt a direct exploit.

Furthermore, resources in private subnets are protected by defense in depth — stacking independent security measures on top of one another. For example, in my build, the database security group only accepts inbound traffic from the web-server security group. This means the database is locked down by both routing *and* firewall: even if the database had a weak password or a vulnerability, an internet attacker can't reach it to exploit it, because the network layer blocks them first.

Lastly, putting critical resources like databases in private subnets reduces the blast radius. If an attacker wants to compromise the database, they first have to compromise the public tier and pivot inward from there — which is much harder to do.

## 2. What traffic is allowed in and out?

**Inbound:** The web tier (`web_sg`) only accepts HTTPS traffic on port 443 from the internet. The database (`db_sg`) only accepts MySQL on port 3306, and that traffic must come from the `web_sg` security group.

**Outbound:** `web_sg` allows all egress, which matters because the web server needs to reach out to external APIs and services. `db_sg`, however, is scoped to HTTPS on port 443 only.

**Private subnet internet access:** To let resources in the private subnet fetch security patches or updates, I *designed* a NAT gateway (outbound-only) and validated it with `terraform plan`, but deliberately left it un-applied to avoid cost. So in the deployed state, the private subnets have no route to the general internet. The NAT is the pattern I'd apply if the private tier needed outbound patching — it would let the database reach *out* for updates while remaining unreachable *in* from the internet.

The private subnets do still get one private path out: an **S3 Gateway VPC Endpoint** attached to their route table. That lets them reach S3 over AWS's internal network — no NAT Gateway, no cost, and no internet exposure. So the private tier stays isolated from the internet while still being able to talk to S3 (for things like backups or reading objects) privately.

## 3. How do security groups and NACLs complement each other?

In my build, I wrote a custom NACL on the public subnets, which adds a subnet-level firewall on top of the security groups. Because NACLs are stateless, I had to write rules for both directions explicitly: inbound 443 for the web traffic, plus the ephemeral port range (1024–65535) inbound so return traffic can get back in, and all outbound. This is different from a security group, which is stateful and automatically allows the return traffic for anything it lets in.

Because a NACL is a subnet-level firewall and a security group is an instance-level firewall, traffic must pass *both* to reach a resource. It's like two gates guarding the resource: the NACL handles subnet-wide controls, while the security group handles the precise rules for accessing that instance. To reach the resource behind those two gates, both must allow the traffic. NACLs are also useful for broad denies — such as blocking a malicious IP range across an entire subnet — which security groups cannot do, since they are allow-only.

## 4. Where would inspection or logging live in a real environment?

In my build, I have not implemented inspection or logging yet. However, if I were to add logging, I would enable it at the VPC level. **VPC Flow Logs** would capture traffic metadata (source/destination IP, ports, protocol, ACCEPT/REJECT) at the VPC level, sent to **CloudWatch Logs** for alerting and/or an **S3 bucket** for archiving. Logging is crucial for visibility into activity in the VPC, and archiving the logs matters so that if something happens, we have a record to investigate with.

For inspection, I could use something like **AWS Network Firewall** — doing domain filtering, intrusion-prevention (IPS) rules, and so on — sitting between the Internet Gateway and my app subnets.

## 5. How does this design reduce attack surface?

This design reduces attack surface in several ways:

- **Segmentation** — public subnets are open to the internet through the IGW, but there is no route from the internet to the private subnet, so private resources are unreachable from outside.
- **Minimal entry points** — the only thing exposed to the internet is port 443 on the web tier. Everything else is denied by default.
- **Identity-based access, not IP** — the `db_sg` only accepts traffic from the `web_sg`, which makes the database invisible to anything but the web tier.
- **Least-privilege egress** — the `db_sg` egress is scoped so only necessary traffic can leave, limiting an attacker's ability to exfiltrate data.
- **Forced pivot** — with all of the above, an attacker who wants to reach the private subnet must first breach the public tier and then pivot inward, which is harder because there's a security control at every step.

## 6. How does it support future growth?

**CIDR headroom** — my VPC uses the CIDR `10.0.0.0/16`, which provides 2^16 (65,536) addresses. The public and private subnets each use only about 256 addresses, leaving plenty of room to add more subnets without redesigning the addressing.

**Multi-AZ for high availability** — the build already spreads both tiers across two AZs (`ap-southeast-1a` and `1b`): `public-a` + `public-b` and `private-a` + `private-b`, created with `for_each` over an AZ→CIDR map. That gives redundancy if a single data center fails, and it's the foundation for running highly-available services later — e.g. a load balancer across both public subnets and a database with a standby in the second AZ.

**Adding tiers** — adding more tiers, like dedicated database subnets or additional app subnets, doesn't require re-architecting the whole VPC. We just create the subnet, its route table, and its security groups — repeating the existing pattern.

**Modularization** — since we use Terraform, we can modularize the code so it can be reused to create identical VPCs as many times as needed — across dev, staging, prod, and beyond.
