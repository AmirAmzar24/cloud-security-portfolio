module "iam" {
  source = "./modules/iam"

  external_id           = var.external_id
  trusted_principal_arn = var.trusted_principal_arn
}
