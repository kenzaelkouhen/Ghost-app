resource "aws_lb" "my_lb" {
  name               = "${var.app_name}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [data.aws_subnet.subnet_1.id, data.aws_subnet.subnet_2.id]

  enable_deletion_protection = false

  tags = {
    Name = "${var.app_name}-load-balancer"
  }
}

resource "aws_lb_listener" "my_listener" {
  load_balancer_arn = aws_lb.my_lb.arn
  port              = 80   # Exposed port for the load balancer
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.arn
  }
}

resource "aws_lb_target_group" "my_target_group" {
  name     = "ghost-target-group"
  port     = 2368  # The port Ghost listens on
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    healthy_threshold   = 2
    interval            = 30
    timeout             = 5
    unhealthy_threshold = 2
    path                = "/"  # Ensure Ghost responds at the root
    port                = "2368"
    protocol            = "HTTP"
    matcher             = "200"
  }

  target_type = "ip"
}

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security group for the Application Load Balancer"
  vpc_id      = data.aws_vpc.default.id

  // Ingress rules
  ingress {
    from_port   = 80          # Allow HTTP traffic
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow from anywhere
  }

  ingress {
    from_port   = 443         # Allow HTTPS traffic
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow from anywhere
  }

  // Egress rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-security-group"
  }
}