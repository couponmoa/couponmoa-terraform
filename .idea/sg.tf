# ALB 보안 그룹
resource "aws_security_group" "alb_sg" {
  name        = "${var.APP_NAME}-alb-sg"
  description = "Allow HTTP/HTTPS to ALB"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.APP_NAME}-alb-sg"
    Environment = var.Environment
  }
}

# ECS 보안 그룹 (ALB + ECS 내부 간 통신 허용)
resource "aws_security_group" "ecs_sg" {
  name        = "${var.APP_NAME}-ecs-sg"
  description = "Allow traffic from ALB and ECS services"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # ECS 서비스들끼리 서로 통신 가능
  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
    description     = "Allow internal ECS to ECS communication"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.APP_NAME}-ecs-sg"
    Environment = var.Environment
  }
}


# RDS 보안 그룹 (ECS에서 들어오는 MySQL 포트 허용)
resource "aws_security_group" "rds_sg" {
  name        = "${var.APP_NAME}-rds-sg"
  description = "Allow MySQL from ECS"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.APP_NAME}-rds-sg"
    Environment = var.Environment
  }
}
