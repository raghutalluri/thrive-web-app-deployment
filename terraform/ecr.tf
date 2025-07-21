# Elastic Container Registry to store our Docker images
resource "aws_ecr_repository" "app_repo" {
  name                 = "thrive-web-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "thrive-app-ecr-repo"
  }
}