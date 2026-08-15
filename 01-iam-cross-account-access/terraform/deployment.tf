# -- Github Actions + DeploymentRole --

# -- TLS Cert --
data "tls_certificate" "github" {
    url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

# -- Register Github's OIDC with this account --
resource "aws_iam_openid_connect_provider" "github" {
    url = "https://token.actions.githubusercontent.com"
    client_id_list = ["sts.amazonaws.com"]
    thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

# -- DeploymentRole Trust Policy --
data "aws_iam_policy_document" "deployment_trust" {
    statement {
        effect = "Allow"
        actions = ["sts:AssumeRoleWithWebIdentity"]
        principals {
            type = "Federated"
            identifiers = [aws_iam_openid_connect_provider.github.arn]
        }

        condition {
            test = "StringEquals"
            variable = "token.actions.githubusercontent.com:aud"
            values = ["sts.amazonaws.com"]
        }

        condition {
            test = "StringLike"
            variable = "token.actions.githubusercontent.com:sub"
            values = ["repo:${var.github_repo}:*"]
        }
    }
}

# -- DeploymentRole --
resource "aws_iam_role" "deployment" {
    name = "GithubActionsDeploymentRole"
    assume_role_policy = data.aws_iam_policy_document.deployment_trust.json
}

# -- DeploymentRole Policy Attachment --
resource "aws_iam_role_policy_attachment" "deployment_readonly" {
    role = aws_iam_role.deployment.name
    policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}