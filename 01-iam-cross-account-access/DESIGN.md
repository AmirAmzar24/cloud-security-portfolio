# Project 1: IAM Cross-Account Access — Design Decisions

## 1. Why did you choose role assumption instead of long-lived credentials?

**Expiration** — If long-lived credentials are leaked, we're in serious trouble. Long-lived credentials present a threat surface that can be exploited by malicious actors. Session credentials, however, have a time limit (`max_session_duration` ~ 1 hour), which limits the window of exploitation. If an attacker successfully compromises a session credential, they only have that limited time before it expires — but if they get a long-lived key, they can stay as long as they want.

**No stored secret** — Role assumption reduces long-lived secrets to at most one (which we then guard with MFA); only OIDC/EC2 instance roles reach zero stored secrets. The fewer permanent secrets sitting on disk, the less an attacker can steal — and the single remaining source key is itself protected by MFA.

**Auditability** — Role assumption also helps with auditability, because CloudTrail records who assumed the role. The role-session-name shows up in the CloudTrail ARN (`assumed-role/RoleName/session-name`), so even the same role used by two different users is distinguishable — we can see who is responsible for what. By contrast, if we don't assume roles and instead share a user's key (like a shared admin that multiple people can access), we don't know who was operating admin when something happens.

**Stronger gates** — Role assumption can require MFA or an ExternalId to assume a role. You cannot put those conditions on a raw access key. I have verified this: assuming `IncidentResponseRole` without MFA is denied, and re-assuming with MFA succeeds. Same for `SecurityAuditRole` — assuming without the ExternalId fails, and re-assuming with the ExternalId succeeds.

**Rotation** — Long-lived credentials have to be rotated manually by a person (if they remember), which is hazardous and prone to human error/neglect. Temporary credentials, however, have a time limit and are destroyed automatically when they expire — making them safer and far less prone to human error/neglect.

## 2. How would this scale to 20 or 100 accounts?

Doing it by hand at that scale introduces **drift** (where one or some of the roles end up different), **toil** (much more manual work), and **human error** (one typo = one security hole).

Since I am only one person with one credit card, I have created each role in a single account. However, the concept still applies to multiple accounts, albeit with slightly different configs. So, to scale this to 20 or 100 accounts: we can use **Organizations/OUs** to manage accounts in groups rather than one-by-one. Then, using **Terraform**, we write reusable **modules** so we only define a role once — this removes drift and human error, as every account gets the same config. We can also set guardrails using **SCPs** (Service Control Policies): even if other accounts have admins who want to create the same role, they cannot grant it excessive privileges, because the SCP caps the blast radius. For human access at scale, **IAM Identity Center** replaces per-account IAM users (like my `admin-amir`) with one central login that federates in and assumes roles into each account — giving humans single sign-on and, like OIDC does for machines, eliminating long-lived keys on disk.

Every role we mass-deploy carries a trust policy pointing back to the central Security Account. So accessing any of the 100 accounts is the same assume-role handshake I built here — one identity assuming into each account. Organizations/StackSets/SCPs are the machinery that mass-produces and guards those roles; cross-account role assumption is the spine that actually connects them.

## 3. What risks exist if a role is over-privileged?

When we talk about risk, we can't avoid talking about the **blast radius**. The blast radius defines how much damage an attacker can do if the credentials are leaked. For an over-privileged role, the blast radius is huge and the damage is catastrophic. However, if the role is scoped properly and given only least-privilege, the blast radius is contained.

An over-privileged role can do more than it should. For example, if an over-privileged role is compromised, it can delete/encrypt resources, exfiltrate data, create backdoor IAM users, pivot into other accounts (privilege escalation and lateral movement), disable CloudTrail (which is especially bad, since we need the logs for digital forensics), or even cryptomine.

For this project, I have scoped `SecurityAuditRole` and `IncidentResponseRole` to least-privilege — only what their job requires and nothing more. For example, if `SecurityAuditRole` leaks, an attacker can read a little EC2 metadata and nothing else; if `IncidentResponseRole` leaks, they can't even terminate an instance (I deliberately excluded `ec2:TerminateInstances`), and the write actions are tag-gated.

## 4. How would you detect misuse?

To detect misuse, I would deploy a CloudTrail + GuardDuty/CloudWatch + EventBridge pipeline. CloudTrail only *records* — a log nobody watches catches nothing — so the detection comes from GuardDuty/EventBridge sitting on top of it, turning recorded events into alerts. I would decide which events should trigger an alert, such as:

- **AssumeRole from an unexpected IP** — if my team works in one region and a random IP from another region assumes the role, that's a red flag.
- **AssumeRole failures** — repeated `AccessDenied` can indicate brute-forcing, e.g. trying to assume the role without MFA or the ExternalId.
- **AssumeRole outside business hours** — uncommon, so worth flagging.
- **Cross-account access from an unapproved account.**
- **Changes to trust policies** — could indicate an attacker trying to widen access or plant a backdoor.

## 5. What happens if the Security Account (main hub) is compromised?

If the Security Account is compromised, we have a big problem. Because we centralized access for every role through the Security Account, we also centralized the risk into it — making it the single high-value target. So we have to make sure the Security Account is the hardest thing to break, and that IF it breaks, the damage is bounded and the evidence survives.

First, we give the Security Account the strictest controls: MFA on every human, no long-lived keys (by using Identity Center login), the fewest people possible with access, and tight SCPs. This shrinks the attack surface as much as possible.

Then we apply **defense in depth**: each assume-role from the Security Account still has to pass the conditions we set (ExternalId and/or MFA). We avoid blind trust, even for requests coming from the Security Account.

We should also separate the CloudTrail logs away from the Security Account into a dedicated **Logging Account**, where logs are write-once and cannot be deleted or altered — not even by the Security Account. This ensures the logs are protected and evidence is preserved in case anything happens.

Lastly, monitor the Security Account the hardest — set up strict detection and alerting rules focused on it (for example, using GuardDuty).

