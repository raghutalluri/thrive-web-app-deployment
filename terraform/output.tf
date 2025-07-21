data "aws_caller_identity" "current" {}

output "aws_account_id" {
  description = "The AWS account ID that Terraform is deploying to."
  value       = data.aws_caller_identity.current.account_id
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.app_lb.dns_name
}

# Output the URL of the ECR repository for the CI/CD pipeline
output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.app_repo.repository_url
}

