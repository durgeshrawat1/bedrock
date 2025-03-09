provider "aws" {
  region = "us-east-2"
}

data "aws_region" "current" {}

module "bedrock_gateway" {
  source = "../modules/bedrock-gateway"

  environment      = var.environment
  vpc_id          = var.vpc_id
  private_subnets = var.private_subnets
  api_key_secret_arn = var.api_key_secret_arn
  default_model_id = var.default_model_id
  ecr_repository_url = "${var.account_id}.dkr.ecr.${data.aws_region.current.name}.${data.aws_region.current.dns_suffix}"
  
  allowed_cidr_blocks = var.allowed_cidr_blocks
  certificate_arn = var.certificate_arn
  access_logs_bucket = var.access_logs_bucket
  log_retention_days = var.log_retention_days
  kms_key_arn = var.kms_key_arn
  
  bedrock_vpc_endpoint_prefix_list = var.bedrock_vpc_endpoint_prefix_list
  secretsmanager_vpc_endpoint_prefix_list = var.secretsmanager_vpc_endpoint_prefix_list
}

output "alb_dns_name" {
  value = module.bedrock_gateway.alb_dns_name
} 