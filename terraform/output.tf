data "aws_caller_identity" "current" {}

output "aws_account_id" {
  description = "The AWS account ID that Terraform is deploying to."
  value       = data.aws_caller_identity.current.account_id
}



