# 1. The Application Load Balancer
resource "aws_lb" "this" {
  name               = var.alb_name
  internal           = var.internal
  load_balancer_type = "application"
  subnets            = var.subnet_ids
  security_groups    = var.security_group_ids

  enable_deletion_protection = false

  tags = {
    Name = var.alb_name
  }
}

# 2. The Target Group (Using 'ip' target type for cross-vpc and Fargate routing)
resource "aws_lb_target_group" "this" {
  name        = "${var.alb_name}-tg"
  port        = var.target_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    protocol            = "HTTP"
    port                = "traffic-port"
    path                = var.health_check_path
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 6
    interval            = 15
    matcher             = "200-399"
  }
}

# 3. The Listener (HTTP for simplicity, though HTTPS is recommended for production)
resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}