# 1. CloudWatch Log Group
resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/echoserver-${var.environment}"
  retention_in_days = 7
}

# 2. IAM Role for Task Execution
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs-execution-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 3. ECS Cluster
resource "aws_ecs_cluster" "this" {
  name = "workload-cluster-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# 4. Task Definition
resource "aws_ecs_task_definition" "this" {
  family                   = "echoserver-task-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256" # 0.25 vCPU
  memory                   = "512" # 512 MB
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name      = "echoserver"
    image     = var.container_image
    essential = true

    portMappings = [{
      containerPort = 8080
      hostPort      = 8080
      protocol      = "tcp"
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.this.name
        "awslogs-region"        = "ap-southeast-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

# 5. ECS Service
resource "aws_ecs_service" "this" {
  name            = "echoserver-service-${var.environment}"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  launch_type     = "FARGATE"
  desired_count   = 2 # Run two tasks for high availability

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    # Set to false because we are in private subnets routing through a NAT Gateway
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "echoserver"
    container_port    = 8080
  }
}