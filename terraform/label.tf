module "label" {
  source    = "git::https://github.com/cloudposse/terraform-null-label.git?ref=0.25.0"
  namespace = var.namespace
  stage     = var.stage
  name      = var.name
  tags      = var.tags
}