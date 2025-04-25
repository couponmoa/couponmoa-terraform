# ALB (Application Load Balancer)
resource "aws_lb" "alb" {
  name               = "${var.APP_NAME}-${var.Environment}-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb_sg.id]  # 보안 그룹 연결
  subnets = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ]

  tags = {
    Name        = "${var.APP_NAME}-alb"
    Environment = var.Environment
  }
}

# ALB Target Group
resource "aws_lb_target_group" "ecs_tg" {
  name        = "${var.APP_NAME}-${var.Environment}-tg"
  port        = 3000                                # ECS가 사용하는 포트
  protocol    = "HTTP"
  target_type = "ip"                                # ECS는 Fargate → IP 방식
  vpc_id      = aws_vpc.vpc.id

  health_check {
    path                = "/actuator/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 300
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.APP_NAME}-tg"
    Environment = var.Environment
  }
}

# ALB Listener
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg.arn
  }
}
