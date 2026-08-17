# Project 3: CI/CD Security Pipeline — Design Decisions

## 1. What checks are included in your pipeline?

The main check is **IaC scanning with Checkov**, which looks for misconfigurations like public buckets, open security groups, and missing encryption. It runs in enforcing mode (`soft_fail: false`), so it blocks the merge on any finding, and it runs on every push and pull request. I also added **Gitleaks** for secret scanning.

The pipeline also runs a **`terraform plan`** using OIDC: it assumes a DeploymentRole with zero stored keys and runs a read-only plan to validate the infrastructure and catch drift. I also included **`terraform fmt -check`** and **`terraform validate`** to keep the formatting consistent and the config valid.

I gate the `terraform plan` job behind the scan (`needs: iac-scan`), so it only runs after the code passes the security scan. This makes sure only code that passed the scan ever touches AWS.

I did not include SAST, DAST, dependency scanning, or container scanning, because those need application code or container images, and this repo is Terraform (infrastructure) only.

## 2. When should a pipeline block vs warn?

A pipeline should block on high-confidence, high-severity issues like hardcoded secrets, open SSH ports or security groups, public buckets, and missing encryption. I actually demonstrated this: I opened a PR that exposed SSH (port 22) to `0.0.0.0/0`, and Checkov (`CKV_AWS_24`) blocked it before it could merge. The pipeline should only warn on low-severity findings and known false positives.

I started the pipeline in warn mode (`soft_fail: true`) so I could triage the findings without blocking anything, then flipped it to blocking mode (`soft_fail: false`) once everything was clean. Starting in warn mode isn't just for triage. It's also how you roll a scanner out onto an existing codebase without getting buried in hundreds of findings on day one: you baseline first, fix or accept each finding, and then turn on enforcement.

## 3. What happens if a security check is too strict?

If a security check is too strict, it can lead to alert fatigue. This happens when there are too many false positives, which makes developers stop trusting the tool and start ignoring or bypassing it. It can also cause a productivity hit if legitimate work keeps getting blocked.

So the checks need to be balanced, so they help everyone without making the work harder. The pipeline should start with high-confidence rules only, track the false-positive rate (and tune a rule if it's too high), make exceptions easy but justified (like `#checkov:skip` with a reason), and expand coverage as trust grows.

I ran into this myself when I first set up the scan on this lab. Several Checkov findings, like the public subnets assigning public IPs and the unattached security groups in an empty lab, were all by design. Blocking on all of them straight away would have been too strict, so I triaged them and documented exceptions instead.

## 4. How would you handle false positives?

First, I would investigate whether it's actually an accepted risk (something I intentionally allow) or a genuine false positive. Once I confirm it's a false positive, I suppress it with a mandatory justification. For example, in my `network.tf`, Checkov flagged `CKV2_AWS_1`, saying the NACL wasn't attached to subnets. But it was attached, through the inline `subnet_ids` argument. Checkov only detects attachment through a separate `aws_network_acl_association` resource, so it was a false positive. I suppressed it with a `checkov:skip` comment and a reason, so it doesn't get flagged on future runs.

But the skip comment is only the mechanism. The real control is the process around it. A suppression should always need a justification (which I do), and it should be reviewed and approved. For example, you can use CODEOWNERS so that any change to security-relevant files needs sign-off from the security team. In stricter or regulated environments, the exception should also be time-bound (it expires) and re-audited regularly. That way, every suppression is a documented, accountable decision instead of a silent bypass. Without that process, `checkov:skip` just becomes an easy way for anyone to quietly turn off a security check. I would also track the false-positive rate: if a rule is mostly false positives, it's better to tune or disable that rule than to make everyone keep suppressing it.

## 5. How would this change in a regulated environment?

In a regulated environment (like PCI-DSS, HIPAA, FedRAMP, or SOC 2), the pipeline isn't just a helpful gate anymore. It becomes part of the compliance evidence, so the requirements get stricter.

First, enforcement gets tighter. More findings block instead of just warn, and a mandatory security scan before any deployment is often a hard requirement. For example, PCI-DSS expects a vulnerability scan before you deploy.

Second, every exception becomes heavier. Instead of just a documented justification, a suppression would also need formal approval, be time-bound so it expires, and be re-audited on a schedule. The governance I described in Q4 goes from being a best practice to a mandatory, enforced process.

Third, audit trails are mandatory. The pipeline has to produce evidence of what was scanned, what passed or failed, who approved each exception, and when. Those records have to be kept and traceable, because auditors will ask for them.

Finally, there are extra controls. There are approved tool lists (FedRAMP, for example, only lets you use vetted tools), formal change management for any change to the pipeline itself, and segregation of duties, where the person who wrote the code or requested the exception can't be the one who approves it. The pipeline would also produce regular compliance reports to prove the controls are actually running.

## 6. How do you balance security with developer productivity?

Because the pipeline runs on every push and PR and normally only takes around 1-2 minutes, developers get fast feedback on their code. That matters, because they can fix a problem immediately, while the code is still fresh in their mind, instead of waiting days for a human reviewer. Checkov also gives a specific check ID and explains what's wrong, so it's easier for the developer to fix it, and it links to remediation docs.

Beyond fast feedback, balance also means keeping the pipeline trustworthy and not a dead end. I keep the signal-to-noise high by tuning out false positives and documenting exceptions, so developers trust the tool instead of ignoring it (a noisy pipeline just gets bypassed). And when something really is a false positive or an accepted risk, developers aren't stuck: they can use `#checkov:skip` with a justification that then gets reviewed, so security is never a hard dead end. Overall, the goal is for security to be an enabler, not just a gatekeeper. Instead of only saying "you can't deploy," the pipeline points out exactly what's wrong and how to fix it. Catching an issue early in the pipeline is cheap, while catching it after a breach is catastrophic, so the pipeline helps developers ship safely rather than just slowing them down.
