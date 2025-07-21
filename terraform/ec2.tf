# Launch Template for the EC2 instances
resource "aws_launch_template" "app_template" {
  name_prefix   = "app-template-"
  image_id      = "ami-0fb653ca2d3203ac1"
  instance_type = "t2.micro"
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  # This user_data script runs on instance startup
  user_data = base64encode(<<-EOF
    #!/bin/bash
    # Update packages and install Docker
    yum update -y
    yum install -y docker
    service docker start

    # Add the ec2-user to the docker group so you can execute Docker commands without using sudo
    usermod -a -G docker ec2-user

    # Create a directory for the app
    mkdir -p /home/ec2-user/app

    # We will create a placeholder docker-compose file.
    # The CI/CD pipeline will overwrite this with the correct image from ECR.
    echo "version: '3.7'
    services:
      web:
        image: public.ecr.aws/e1j4s8s3/hello-world-app:latest # A public placeholder image
        ports:
          - '3000:3000'
    " > /home/ec2-user/app/docker-compose.yml
    EOF
  )

  tags = {
    Name = "app-launch-template"
  }
}

# Auto Scaling Group to manage the EC2 instances
resource "aws_autoscaling_group" "app_asg" {
  name                = "thrive-app-asg"
  desired_capacity    = 2
  max_size            = 4
  min_size            = 1
  vpc_zone_identifier = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  launch_template {
    id      = aws_launch_template.app_template.id
    version = "$Latest"
  }

  # Attach the ASG to the Load Balancer's Target Group
  target_group_arns = [aws_lb_target_group.app_tg.arn]

  # This tag is crucial for the CI/CD pipeline to find the instances via SSM
  tag {
    key                 = "Deployment"
    value               = "hello-world-app"
    propagate_at_launch = true
  }
}
