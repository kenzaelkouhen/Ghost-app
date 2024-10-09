resource "aws_vpc" "app_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "${var.app_name}-vpc" }
}

resource "aws_subnet" "app_subnet" {
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
  tags = { Name = "${var.app_name}-subnet" }
}

resource "aws_security_group" "app_sg" {
  vpc_id = aws_vpc.app_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.app_name}-sg" }
}

resource "aws_db_instance" "app_db" {
  identifier              = "${var.app_name}-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t2.micro"  # Free tier eligible
  allocated_storage       = 20
  username               = var.db_username
  password               = var.db_password
  db_name                = "ghost"
  skip_final_snapshot    = true
  vpc_security_group_ids  = [aws_security_group.app_sg.id]
  tags = { Name = "${var.app_name}-db" }
}

resource "aws_ecr_repository" "app_repo" {
  name = "${var.app_name}-repo"
}

resource "aws_ecs_cluster" "app_cluster" {
  name = "${var.app_name}-cluster"
}

resource "aws_ecs_task_definition" "app_task" {
  family                   = "${var.app_name}-task"
  requires_compatibilities = ["EC2"]
  network_mode            = "bridge"
  cpu                     = "256"
  memory                  = "512"

  container_definitions = jsonencode([{
    name  = "${var.app_name}-container"
    image = "${aws_ecr_repository.app_repo.repository_url}:latest"
    memory = 512
    cpu    = 256
    portMappings = [{
      containerPort = 80
      hostPort      = 80
      protocol      = "tcp"
    }]
    environment = [
      { name  = "DB_HOST"; value = aws_db_instance.app_db.address },
      { name  = "DB_USER"; value = var.db_username },
      { name  = "DB_PASS"; value = var.db_password }
    ]
  }])
}

resource "aws_ecs_service" "app_service" {
  name            = "${var.app_name}-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.app_task.id
  desired_count   = 1
  launch_type     = "EC2"
  depends_on      = [aws_db_instance.app_db]

  load_balancer {
    target_group_arn = aws_lb_target_group.app_target_group.arn
    container_name   = "${var.app_name}-container"
    container_port   = 80
  }

  tags = { Name = "${var.app_name}-service" }
}

resource "aws_lb" "app_lb" {
  name               = "${var.app_name}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app_sg.id]
  subnets            = [aws_subnet.app_subnet.id]
  enable_deletion_protection = false
}

resource "aws_lb_target_group" "app_target_group" {
  name     = "${var.app_name}-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.app_vpc.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold  = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_target_group.arn
  }
}
