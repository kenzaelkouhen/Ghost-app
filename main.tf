

resource "aws_security_group" "sg" {
  name   = "sg"
  vpc_id = "vpc-0d5b654c20f1688f5"  

  ingress {
    from_port   = 2368
    to_port     = 2368
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecr_repository" "app_repo" {
  name = "${var.app_name}-repo"
}

resource "aws_ecs_cluster" "app_cluster" {
  name = "${var.app_name}-cluster"
}

resource "aws_ecs_task_definition" "ghost_task" {
  family                   = "${var.app_name}-task"
  execution_role_arn      = aws_iam_role.ecs_execution_role.arn
  network_mode            = "awsvpc"
  cpu   = 256
  memory = 512
  
  container_definitions = jsonencode([
    {
      name      = "ghost"
      image     = "574632954887.dkr.ecr.us-east-1.amazonaws.com/ghost-app-repo:latest"
      essential = true
      portMappings = [
        {
          containerPort = 2368
          hostPort      = 2368
          protocol      = "tcp"
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "ghost_service" {
  name            = "${var.app_name}-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.ghost_task.arn
  desired_count   = 2  # Maintain 2 tasks
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = ["subnet-0928b9f8459f74a83", "subnet-0787f7cfae0f5f1bd"] 
    security_groups  = [aws_security_group.sg.id]
    assign_public_ip = true
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

output "public_ips" {
  value = aws_ecs_service.ghost_service.network_configuration[0].assign_public_ip
}


