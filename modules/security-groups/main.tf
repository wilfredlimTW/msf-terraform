# ==========================================
# INTERNET VPC SECURITY GROUPS
# ==========================================

resource "aws_security_group" "internet_alb" {
  name        = "internet-alb-sg-${var.environment}"
  description = "Allow inbound HTTP/HTTPS from the internet"
  vpc_id      = var.internet_vpc_id

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outbound to Workload VPC via TGW"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    # Note: Cross-TGW requires CIDR referencing, not SG referencing
    cidr_blocks = [var.workload_vpc_cidr]
  }
}

# ==========================================
# WORKLOAD VPC SECURITY GROUPS
# ==========================================

resource "aws_security_group" "workload_nlb" {
  name        = "workload-nlb-sg-${var.environment}"
  description = "Allow inbound traffic from Internet VPC over TGW"
  vpc_id      = var.workload_vpc_id

  ingress {
    description = "HTTP from Internet VPC CIDR"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.internet_vpc_cidr]
  }

  egress {
    description = "Outbound to Workload ALB"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    # We will add the destination SG dynamically in a separate rule to avoid circular logic
  }
}

resource "aws_security_group" "workload_alb" {
  name        = "workload-alb-sg-${var.environment}"
  description = "Allow inbound traffic from Workload NLB"
  vpc_id      = var.workload_vpc_id

  ingress {
    description     = "HTTP from Workload NLB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.workload_nlb.id]
  }

  # Egress to ECS is handled in a separate rule below
}

# Link NLB Egress to ALB Ingress
resource "aws_security_group_rule" "nlb_to_alb_egress" {
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.workload_nlb.id
  source_security_group_id = aws_security_group.workload_alb.id
}

resource "aws_security_group" "ecs_tasks" {
  name        = "ecs-tasks-sg-${var.environment}"
  description = "Allow inbound from Workload ALB"
  vpc_id      = var.workload_vpc_id

  ingress {
    description     = "Traffic from Workload ALB"
    from_port       = 8080 # echoserver runs on 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.workload_alb.id]
  }

  egress {
    description = "Outbound to anywhere (needed to pull images via NAT and talk to DB)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Link ALB Egress to ECS Ingress
resource "aws_security_group_rule" "alb_to_ecs_egress" {
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.workload_alb.id
  source_security_group_id = aws_security_group.ecs_tasks.id
}

resource "aws_security_group" "aurora_db" {
  name        = "aurora-db-sg-${var.environment}"
  description = "Allow inbound PostgreSQL traffic from ECS tasks"
  vpc_id      = var.workload_vpc_id

  ingress {
    description     = "PostgreSQL from ECS Tasks"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }
}