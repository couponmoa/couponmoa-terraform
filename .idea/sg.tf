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

# ECS 보안 그룹
resource "aws_security_group" "ecs_sg" {
  name        = "${var.APP_NAME}-ecs-sg"
  description = "Allow traffic from ALB and ECS services"
  vpc_id      = aws_vpc.vpc.id

  # ALB에서 들어오는 트래픽 허용 (예: 3000번 포트)
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description     = "Allow traffic from ALB"
  }

  # ECS 서비스들끼리 내부 통신 허용
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
    description = "Allow ECS internal communication"
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

# RDS 보안 그룹
resource "aws_security_group" "rds_sg" {
  name        = "${var.APP_NAME}-rds-sg"
  description = "Allow MySQL from ECS"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
    description     = "Allow MySQL access from ECS"
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

resource "aws_security_group" "redis_sg" {
  name        = "couponmoa-redis-sg"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
    description     = "Allow Redis access from ECS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "couponmoa-redis-sg"
    Environment = var.Environment
  }
}

// elasticsearch
resource "aws_security_group" "elasticsearch_sg" {
  name        = "elasticsearch-sg"
  description = "Allow internal access to Elasticsearch"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "Allow from inside VPC"
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "elasticsearch-sg"
  }
}
