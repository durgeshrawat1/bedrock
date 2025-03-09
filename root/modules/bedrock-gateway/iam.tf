# Provider configuration for GitLab Runner role assumption
provider "aws" {
  assume_role {
    role_arn = "arn:aws:iam::${var.account_id}:role/gitlab-cicd-runner-iam-role"
  }
}


# Add this policy to your existing IAM configuration
resource "aws_iam_role_policy" "lambda_secrets" {
  name = "${local.name_prefix}-secrets-access"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.api_key.arn
        ]
      }
    ]
  })
}

# Lambda Execution Role
resource "aws_iam_role" "lambda_execution_role" {
  name = "${local.name_prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]

  tags = local.common_tags
}

# Lambda CloudWatch Logs policy
resource "aws_iam_role_policy" "lambda_logs" {
  name = "${local.name_prefix}-logs-policy"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "${aws_cloudwatch_log_group.proxy_api.arn}:*"
        ]
      }
    ]
  })
}

# Lambda VPC access policy (read-only permissions)
resource "aws_iam_role_policy" "lambda_vpc" {
  name = "${local.name_prefix}-vpc-policy"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs"
        ]
        Resource = ["*"]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = ["*"]
        Condition = {
          StringEquals = {
            "ec2:vpc": var.vpc_id,
            "ec2:subnet": var.private_subnets
          }
        }
      }
    ]
  })
}

# Allow access to Bedrock with specific model restrictions
resource "aws_iam_role_policy" "bedrock_policy" {
  name = "${local.name_prefix}-bedrock-policy"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:ListFoundationModels",
          "bedrock:ListInferenceProfiles"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = [
          "arn:aws:bedrock:*::foundation-model/${var.default_model_id}",
          "arn:aws:bedrock:*::foundation-model/cohere.embed-multilingual-v3"
        ]
      }
    ]
  })
}

# Allow reading specific API key from Secrets Manager
resource "aws_iam_role_policy" "secrets_policy" {
  name = "${local.name_prefix}-secrets-policy"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [var.api_key_secret_arn]
      }
    ]
  })
}

# KMS decrypt policy for CloudWatch Logs encryption
resource "aws_iam_role_policy" "kms_policy" {
  count = var.kms_key_arn != null ? 1 : 0
  name  = "${local.name_prefix}-kms-policy"
  role  = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = [var.kms_key_arn]
      }
    ]
  })
} 
