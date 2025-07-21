# Application Load Balancer to distribute traffic
resource "aws_lb" "app_lb" {
  name               = "thrive-app-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = {
    Name = "thrive-app-alb"
  }
}

# Target Group for the Load Balancer
# The ALB forwards requests to the instances in this group.
resource "aws_lb_target_group" "app_tg" {
  name     = "app-target-group"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id


  health_check {
    path                = "/health" # Points to the /health endpoint in our Node.js app
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 10
  }

  tags = {
    Name = "thrive-app-target-group"
  }
}

# Listener for the Load Balancer
# Listens for incoming HTTP traffic on port 80 and forwards it to the target group.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}