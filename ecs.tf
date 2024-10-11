resource "aws_ecs_cluster" "app_cluster" {
  name = "${var.app_name}-cluster"
}

resource "aws_security_group" "ecs_sg" {
  name        = "ecs-service-sg"
  description = "Security group for ECS service"
  vpc_id      = "vpc-0b587c14daf24f26c"

  // Ingress rule
  ingress {
    from_port   = 2368
    to_port     = 2368
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  // Allow traffic from anywhere
  }

  // Egress rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  // Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ECS Service Security Group"
  }
}

resource "aws_ecs_task_definition" "ghost_task" {
  family                   = "${var.app_name}-task"
  execution_role_arn      = aws_iam_role.ecs_execution_role.arn
  network_mode            = "awsvpc"
  cpu                     = 256
  memory                  = 512

  container_definitions = jsonencode([
    {
      name      = "ghost-container"
      image = "724772094190.dkr.ecr.us-east-1.amazonaws.com/ghost-app-repo:latest"
      essential = true
      portMappings = [
        {
          containerPort = 2368  # Ghost's default port
          hostPort      = 2368   # Port to access the container
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "NODE_ENV"
          value = "development"
        },
        {
          name  = "url"
          value = "http://${aws_lb.my_lb.dns_name}:3001"  
        }
      ]
    }
  ])
}


resource "aws_ecs_service" "ghost_service" {
  name            = "${var.app_name}-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.ghost_task.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = ["subnet-0250e1c137131e1dc", "subnet-0f3054a95428ef993"]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.my_target_group.arn
    container_name   = "ghost-container"
    container_port   = 2368
  }
}

resource "aws_appautoscaling_target" "ecs_service_target" {
  max_capacity       = 10  # Maximum tasks
  min_capacity       = 2   # Minimum tasks
  resource_id        = "service/${aws_ecs_cluster.app_cluster.name}/${aws_ecs_service.ghost_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}


resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_execution_role.name
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.app_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}




