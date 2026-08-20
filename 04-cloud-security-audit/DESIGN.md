# Project 4: Cloud Security Audit — Design Decisions

## 1. How do you distinguish signal from noise?

To distinguish between signal and noise, I first need to actually understand what my account is for and understand properly what the findings are about. Misunderstanding the findings can cause panic and wasted time remediating something that is already configured securely.

One thing that makes the findings easy to misread is that Prowler writes its check titles as the good/desired state, so a FAIL actually means I don't meet it, not that something bad is happening. For example, the check `iam_user_administrator_access_policy` reads like "IAM user does not have AdministratorAccess", so seeing it FAIL looks scary at first, but all it really means is that my admin user (admin-amir) has AdministratorAccess, which is by design.

After correctly understanding the findings, I categorize them into buckets:

- **not-applicable** — like Organizations rules, since this is a personal/standalone account.
- **paid-services** — which I'm currently avoiding so as not to bleed money while doing this project.
- **deferred** — because I have plans to do them in future projects, like CloudWatch logging in Project 5.
- **accept** — acceptable findings with clarification given the nature of this project, like giving the AdministratorAccess policy to the admin-amir IAM user since that is my admin user for this project.
- **fix** — something I can remediate immediately.

The point of triaging the findings is not to make sure I pass ALL the checks or get the next scan to 0 findings, but to actually understand what I can do to remediate the REAL risks.

## 2. Which findings actually matter in this context?

When it comes to Prowler findings, the severity status doesn't necessarily determine its priority on what to remediate first. Context decides what is actually the top priority to remediate, based on the project. For example, Prowler flags my IAM user admin-amir for having the AdministratorAccess policy attached as Critical, but given my AWS account structure (personal, not organizational), admin-amir IS my admin (and it is protected by MFA). Prowler also flags my root account as Critical for not having a hardware MFA device enabled, but personally I think that is overkill, and my root account DOES have virtual MFA instead.

To flip it, the findings that actually mattered to me were the ones I chose to fix straight away, even when some of them were a lower severity than the Criticals I accepted. A good example is Prowler flagging my account for not having an account-level public access block for S3 buckets. This one was only a High, but it mattered more to me than the accepted Criticals because it is a real risk: without it, a new bucket I create later could accidentally be made public if I forget to block it at the individual level (right now each bucket blocks public access on its own, but an account-level block is defense in depth on top of that). The other three I fixed for the same reason — they were real gaps that were cheap to close: I had no account password policy at all (weak passwords are an easy way in), my state bucket allowed non-HTTPS access (so data could be read in transit), and I had no IAM Access Analyzer (nothing was watching for resources being shared outside my account). So the point is that I fixed a High before I accepted a Critical, because in my context the High was the actual risk and the Critical was by design.

## 3. What would be accepted risks in a real organization?

Accepted risks are the findings that I acknowledge are real but consciously choose not to fix, with clear reasoning behind it. The important part is that these are documented decisions, not findings that I ignored or missed. In my project there are a few of these.

The first one is my state bucket using SSE-S3 (AES256) encryption instead of KMS. Prowler flags this, but the bucket IS still encrypted, and using a KMS customer-managed key would add key-management overhead and a bit of cost that I don't need for a solo lab. So the risk (no customer-managed key) is accepted because the data is still encrypted at rest.

Next is the same bucket not having MFA-delete enabled. This one can't even be set through Terraform (it needs the root user and the CLI), and I already have versioning turned on, which protects me from accidental or malicious deletion since old versions can be recovered. So versioning is the compensating control that makes this acceptable.

Another one is my security groups being flagged as unused. This is true — they are not attached to anything — but that is by design, because this is an empty network scaffold with no EC2 instances running (which is also why I'm not paying for compute). I made the same call in my Project 3 Checkov scan (`CKV2_AWS_5`). The security groups themselves are still locked down, so an unused-but-tight SG is not a real risk.

Prowler also flags my default VPC and its default NACLs for being wide open. These were created automatically by AWS, and I don't use them at all — my real workload lives in the custom VPC I built in Project 2. In a real organization the proper fix would be to just delete the default VPC entirely so it can't be used by accident, but for this project I accept it since nothing is deployed into it.

Lastly, a big chunk of findings are about AWS Organizations, SCPs, and delegated admins. These are not really accepted risks — they are just not-applicable to me, because I only have one standalone account and not an organization with multiple accounts. There is nothing to accept or fix here; they simply don't apply to my setup.

In a real organization the pattern is the same: a risk is only acceptable if someone understands it, writes down why, and there is a compensating control or a business reason behind it. An accepted risk with reasoning is a decision; an ignored finding is just negligence.

## 4. How would you prioritize remediation over time?

The way I prioritize is based on risk versus cost and effort, and I split it into phases instead of trying to fix everything at once.

The first phase is what I already did: the quick wins that are free and high value. These are the account password policy, the account-level S3 public access block, enabling IAM Access Analyzer, and forcing HTTPS-only on my state bucket. All of them close a real gap, cost nothing, and only took a bit of Terraform, so there was no reason to delay them.

The next phase is the near-term stuff that I am deferring on purpose. The biggest one here is the whole monitoring and logging gap — things like multi-region CloudTrail and the CloudWatch alarms for events like root usage or security group changes. These matter, but they belong to a proper logging setup, so I am rolling them into my Project 5 (Centralized Logging) instead of half-doing them here.

After that is the later phase: the paid enterprise detection services like GuardDuty, Security Hub, AWS Config, Macie, and Inspector. These are genuinely good best practices in a real environment, but they cost money and I am keeping this account at zero cost, so in a real organization I would turn them on once the account actually holds something worth paying to protect.

And finally, it is ongoing, not a one-time thing. Every time I change my infrastructure I re-scan so I can catch anything that regresses, and re-check whether any of the accepted or deferred risks now need to be revisited (for example, once paid services get enabled). So the order is basically: fix the cheap real risks now, schedule the bigger pieces into the right project, defer the paid ones until they are justified, and keep scanning so nothing slips back.

## 5. What compensating controls might justify accepting a risk?

A compensating control is basically a different control that lowers a risk enough that the original finding becomes acceptable, even though I didn't fix the finding directly. It is the reasoning that turns an accepted risk from "I ignored it" into "I handled it another way". A lot of my accepted risks in question 3 are only acceptable because of these.

The clearest example is the MFA-delete finding on my state bucket. I can't enable MFA-delete through Terraform, but I have versioning turned on, so if an object gets deleted or overwritten (by accident or maliciously) the old version is still recoverable. Versioning is the compensating control that makes the missing MFA-delete acceptable.

Another one is admin-amir having AdministratorAccess. The risk of a full-admin user is that if the credentials leak, an attacker gets everything. My compensating control is that the user has MFA enabled, so a leaked password alone is not enough to log in, and I can also see activity through CloudTrail if anything looks wrong.

For the root account, Prowler wants a hardware MFA device, which I don't have. The compensating control is that root still has virtual MFA (an authenticator app), so root is not sitting there protected by only a password. Virtual MFA is weaker than a physical key, but it still blocks the main risk, which is someone logging in with just a stolen password.

For the state bucket using SSE-S3 instead of KMS, the compensating control is simply that the data is still encrypted at rest with AES256, and the bucket also blocks public access and now denies non-HTTPS traffic. So even without a customer-managed KMS key, the data is not sitting there in plaintext or reachable by the public.

So the pattern is that I don't accept a risk just because it is inconvenient to fix — I accept it when there is another control already reducing that same risk to a level I'm comfortable with.

## 6. How would you present this to non-technical leadership?

Leadership doesn't care about check IDs or severity labels — they care about what the risk means for the business and what I'm doing about it. So I would drop all the technical jargon and frame everything as risk and outcome.

I would start with a short executive summary, something like: we scanned the whole AWS account against an industry best-practice standard (CIS); most of the findings were either not applicable to our setup or low priority; we fixed the important ones that were cheap to fix; and there are no critical issues left that are not already accounted for.

Then I would give the before and after in plain numbers: the scan started with 89 failing checks, and after remediation it is down to 80, with 10 real risks closed. I would explain that the goal was never to reach zero, because a lot of the remaining findings either don't apply to us or would cost money that isn't justified yet.

For the actual findings I would translate them into business language. Instead of "`s3_bucket_secure_transport_policy` FAIL" I would say "data could have been read while travelling over an unencrypted connection, and we have now closed that". Instead of "no account password policy" I would say "we now enforce strong passwords across all users". The point is to talk about the impact, not the tool output.

I would also be honest about the accepted risks and why, so leadership knows they were conscious decisions and not things we missed. And I would end with the roadmap: what we are doing next (the logging and monitoring in a later phase) and what would make us turn on the paid security services. That way leadership sees the current state, the decisions behind it, and the plan going forward, without needing to understand any of the technical detail.