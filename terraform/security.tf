# security group for the ALB

resource aws_security_group "alb_sg" {
  name        = "thrive-web-app-sg"
  description = "Allow HTTP traffice to ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "thrive-web-app-alb-sg"
  }
}

# security group for the EC2 instances

resource "aws_security_group" "ec2_sg" {
  name        = "thrive-web-app-ec2-sg"
  description = "Allow HTTP traffic to EC2 instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description = "Allow HTTP traffic from ALB"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = data.aws_ip_ranges.ec2_instance_connect.cidr_blocks
    description = "Allow SSH from EC2 Instance Connect"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "thrive-web-app-ec2-sg"
  }
}


# Data source to get the IP ranges for the EC2 Instance Connect service
data "aws_ip_ranges" "ec2_instance_connect" {
  regions  = [data.aws_region.current.name]
  services = ["EC2_INSTANCE_CONNECT"]
}

data "aws_region" "current" {}