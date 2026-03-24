# 1. The Network Load Balancer
resource "aws_lb" "this" {
  name               = "workload-nlb-${var.environment}"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.subnet_ids
  security_groups    = var.security_group_ids

  enable_deletion_protection = false

  tags = {
    Name = "workload-nlb-${var.environment}"
    Tier = "Web"
  }
}

# 2. The Target Group (pointing to the upcoming ALB)
resource "aws_lb_target_group" "this" {
  name        = "workload-nlb-tg-${var.environment}"
  port        = 80
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "alb" # Native support for ALB targets

  health_check {
    protocol            = "HTTP"
    port                = "traffic-port"
    path                = "/health" # Ensure your echoserver responds here
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 6
    interval            = 10
  }
}

# 3. The Listener
resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# 4. Dynamic IP Fetching (Pro-Tip)
# We fetch the Elastic Network Interfaces (ENIs) automatically created
# by the NLB so we can export their IP addresses for the Transit Gateway.
data "aws_network_interface" "nlb" {
  count = length(var.subnet_ids)

  filter {
    name   = "description"
    values = ["ELB ${aws_lb.this.arn_suffix}"]
  }

  filter {
    name   = "subnet-id"
    values = [var.subnet_ids[count.index]]
  }

  # Ensure the NLB is fully provisioned before querying its interfaces
  depends_on = [aws_lb.this]
}