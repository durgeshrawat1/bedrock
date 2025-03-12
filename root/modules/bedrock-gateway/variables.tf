variable "use_docker_provider" {
  description = "Whether to use Docker provider (true) or shell commands (false) for building/pushing images"
  type        = bool
  default     = false
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
  default     = "lab"
}

variable "app_prefix" {
  description = "Application prefix for all resources"
  type        = string
  default     = "APP1234"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    tfc-cost-center = "your-cost-center"
    tfc-app-name    = "bedrock-gateway"
    tfc-owner       = "your-team-name"
    Environment     = "lab"
  }
}

variable "artifactory_url" {
  description = "Artifactory registry URL"
  type        = string
}

variable "artifactory_repository" {
  description = "Artifactory repository name"
  type        = string
}

variable "artifactory_username" {
  description = "Username for Artifactory (can be sourced from Vault or other secret stores)"
  type        = string
  sensitive   = true
}

variable "artifactory_password" {
  description = "Password for Artifactory (can be sourced from Vault or other secret stores)"
  type        = string
  sensitive   = true
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs (minimum 2 required)"
  type        = list(string)
  validation {
    condition     = length(var.private_subnets) >= 2
    error_message = "At least 2 private subnets are required for high availability."
  }
}

#variable "api_key_secret_arn" {
#  description = "ARN of the secret containing the API key in AWS Secrets Manager"
#  type        = string
#}

variable "default_model_id" {
  description = "Default Bedrock model ID"
  type        = string
  default     = "anthropic.claude-3-sonnet-20240229-v1:0"
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the ALB"
  type        = list(string)
}

variable "access_logs_bucket" {
  description = "S3 bucket for ALB access logs"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "kms_key_arn" {
  description = "ARN of KMS key for CloudWatch logs encryption"
  type        = string
  default     = null
}

variable "bedrock_vpc_endpoint_prefix_list" {
  description = "Prefix list ID for Bedrock VPC endpoint"
  type        = string
}

variable "secretsmanager_vpc_endpoint_prefix_list" {
  description = "Prefix list ID for Secrets Manager VPC endpoint"
  type        = string
}

variable "vault_address" {
  description = "Address of the on-premises Vault server"
  type        = string
}

variable "vault_auth_username" {
  description = "Username for Vault basic auth"
  type        = string
  sensitive   = true
}

variable "vault_auth_password" {
  description = "Password for Vault basic auth"
  type        = string
  sensitive   = true
}

variable "vault_artifactory_secret_path" {
  description = "Path in Vault where Artifactory credentials are stored"
  type        = string
}

variable "pip_conf_content" {
  description = "Content of pip.conf file to be used in the Docker build"
  type        = string
  default     = <<-EOT
[global]
index-url = https://pypi.org/simple
EOT
} 


variable "api_key_secret_name" {
  type        = string
  description = "Name of the existing Secrets Manager secret containing the API key"
}

variable "initial_api_key" {
  type        = string
  description = "Initial API key value to be stored in Secrets Manager"
  sensitive   = true
}

variable "docker_image_uri" {
  description = "URI of the Docker image to use if not building with Docker"
  type        = string
}
