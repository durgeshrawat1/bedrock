terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  name_prefix = "${var.app_prefix}-${var.environment}"
  common_tags = merge(var.tags, {
    Environment = var.environment
  })
  # Use the appropriate image URI based on the build method
  lambda_image_uri = var.use_docker_provider ? docker_image.bedrock_gateway[0].name : var.docker_image_uri
}


resource "aws_secretsmanager_secret" "api_key" {
  name        = "${local.name_prefix}/api-key"
  description = "API Key for Bedrock Gateway"
  tags        = local.common_tags
}


# Lambda Function
resource "aws_lambda_function" "proxy_api_handler" {
  image_uri        = local.lambda_image_uri
  package_type     = "Image"
  function_name    = "${local.name_prefix}-bedrock-gateway"
  role            = aws_iam_role.lambda_execution_role.arn
  architectures   = ["arm64"]
  timeout         = 600
  memory_size     = 1024

  vpc_config {
    subnet_ids         = var.private_subnets
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DEBUG                        = "false"
      API_KEY_SECRET_ARN          = aws_secretsmanager_secret.api_key.arn  # Updated to use local secret
      DEFAULT_MODEL               = var.default_model_id
      DEFAULT_EMBEDDING_MODEL     = "cohere.embed-multilingual-v3"
      ENABLE_CROSS_REGION_INFERENCE = "true"
    }
  }

  depends_on = [
    docker_image.bedrock_gateway,
    null_resource.docker_build_push
  ]
  tags = local.common_tags
}

# Application Load Balancer
resource "aws_lb" "proxy_alb" {
  name               = "${local.name_prefix}-bedrock-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets           = var.private_subnets

  enable_deletion_protection = false  # Match reference template

  access_logs {
    bucket  = var.access_logs_bucket
    prefix  = "${local.name_prefix}-bedrock-alb"
    enabled = true
  }

  tags = local.common_tags
}

# ALB Target Group
resource "aws_lb_target_group" "proxy_lambda" {
  name        = "${local.name_prefix}-bedrock-tg"
  target_type = "lambda"

  health_check {
    enabled = false
  }

  tags = local.common_tags
}

resource "aws_lb_target_group_attachment" "proxy_lambda" {
  target_group_arn = aws_lb_target_group.proxy_lambda.arn
  target_id        = aws_lambda_function.proxy_api_handler.arn
  depends_on       = [aws_lambda_permission.proxy_api_handler_invoke]
}

# ALB Listener
resource "aws_lb_listener" "proxy" {
  load_balancer_arn = aws_lb.proxy_alb.arn
  port              = "80"  # Changed to HTTP
  protocol          = "HTTP"  # Changed to HTTP

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.proxy_lambda.arn
  }

  tags = local.common_tags
}

# Lambda permission for ALB
resource "aws_lambda_permission" "proxy_api_handler_invoke" {
  statement_id  = "AllowALBInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.proxy_api_handler.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.proxy_lambda.arn
}

# Security Groups
resource "aws_security_group" "alb" {
  name_prefix = "${local.name_prefix}-alb-sg"
  vpc_id      = var.vpc_id
  description = "Security group for Bedrock Gateway ALB"

  ingress {
    description = "Allow HTTP from allowed CIDRs"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "Allow Lambda invocation"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.lambda.id]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb-sg"
  })
}

resource "aws_security_group" "lambda" {
  name_prefix = "${local.name_prefix}-lambda-sg"
  vpc_id      = var.vpc_id
  description = "Security group for Bedrock Gateway Lambda function"

  ingress {
    description     = "Allow ALB traffic"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow HTTPS to AWS services via VPC Endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    prefix_list_ids = [
      var.bedrock_vpc_endpoint_prefix_list,
      var.secretsmanager_vpc_endpoint_prefix_list
    ]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-lambda-sg"
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "proxy_api" {
  name              = "/aws/lambda/${local.name_prefix}-bedrock-gateway"
  retention_in_days = var.log_retention_days
  kms_key_id       = var.kms_key_arn

  tags = local.common_tags
} 
