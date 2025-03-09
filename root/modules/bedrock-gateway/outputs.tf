output "api_base_url" {
  description = "Proxy API Base URL (OPENAI_API_BASE)"
  value       = "http://${aws_lb.proxy_alb.dns_name}/api/v1"
} 