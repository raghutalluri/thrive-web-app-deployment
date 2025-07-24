# Launch Template for the EC2 instances
# This defines the configuration for instances launched by the Auto Scaling Group
resource "aws_launch_template" "app_template" {
  name_prefix   = "thrive-app-template-"
  image_id      = "ami-0370248b8ebbb99af" # Verified Amazon Linux 2 AMI for us-east-2
  instance_type = "t3.micro"

  key_name      = "thrive-key"
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  # Final, working user_data script using the robust cloud-config format
  user_data = base64encode(<<-EOF
    #cloud-config
    output:
      all: "| tee -a /var/log/cloud-init-output.log | tee /dev/console"
    package_update: true
    packages:
      - docker
      - ec2-instance-connect
    runcmd:
      - set -x
      - service docker start
      - usermod -a -G docker ec2-user
      - curl -L "https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
      - chmod +x /usr/local/bin/docker-compose
      - |
        cat <<'EOT' > /home/ec2-user/docker-compose.yml
        version: '3.7'
        services:
          web:
            image: nginxdemos/hello
            ports:
              - '3000:80'
        EOT
      - cd /home/ec2-user && /usr/local/bin/docker-compose up -d
    EOF
  )

  tags = {
    Name = "thrive-app-launch-template"
  }
}

# Auto Scaling Group to manage the EC2 instances
resource "aws_autoscaling_group" "app_asg" {
  name                = "thrive-app-asg"
  desired_capacity    = 2 # Start with two instances for high availability
  max_size            = 4 # Allow scaling up to 4 instances
  min_size            = 1 # Keep at least 1 instance running
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

  tag {
    key                 = "Name"
    value               = "thrive-app-instance"
    propagate_at_launch = true
  }
}