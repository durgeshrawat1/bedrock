# Common variables
environment = "lab"
account_id  = "your-aws-account-id"

# Tags
tags = {
  tfc-cost-center = "your-cost-center"
  tfc-app-name    = "bedrock-gateway"
  tfc-owner       = "your-team-name"
}

# Security and Compliance
allowed_cidr_blocks = ["10.0.0.0/8"] # Your internal network CIDR
log_retention_days = 90
kms_key_arn = "arn:aws:kms:region:account:key/xxxxx"

# US East 1 (Virginia) variables
useast1_vpc_id          = "vpc-xxxxx"
useast1_private_subnets = ["subnet-xxxxx1", "subnet-xxxxx2"]
useast1_api_key_secret_arn = "arn:aws:secretsmanager:us-east-1:your-account-id:secret:your-secret-name"
useast1_certificate_arn = "arn:aws:acm:us-east-1:your-account-id:certificate/xxxxx"
useast1_access_logs_bucket = "your-alb-logs-bucket-us-east-1"
useast1_bedrock_vpc_endpoint_prefix_list = "pl-xxxxx"
useast1_secretsmanager_vpc_endpoint_prefix_list = "pl-yyyyy"

# US East 2 (Ohio) variables
useast2_vpc_id          = "vpc-yyyyy"
useast2_private_subnets = ["subnet-yyyyy1", "subnet-yyyyy2"]
useast2_api_key_secret_arn = "arn:aws:secretsmanager:us-east-2:your-account-id:secret:your-secret-name"
useast2_certificate_arn = "arn:aws:acm:us-east-2:your-account-id:certificate/yyyyy"
useast2_access_logs_bucket = "your-alb-logs-bucket-us-east-2"
useast2_bedrock_vpc_endpoint_prefix_list = "pl-aaaaa"
useast2_secretsmanager_vpc_endpoint_prefix_list = "pl-bbbbb"

# Optional: Override default model ID if needed
# default_model_id = "anthropic.claude-3-sonnet-20240229-v1:0" 