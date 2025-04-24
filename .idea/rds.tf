# RDS Subnet Group (퍼블릭 서브넷을 임시로 사용)
resource "aws_db_subnet_group" "default" {
  name        = "${var.APP_NAME}-db-subnet-group"
  description = "DB Subnet Group for ${var.APP_NAME} (dev only)"
  subnet_ids  = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  tags = {
    Name        = "${var.APP_NAME}-db-subnet-group"
    Environment = var.Environment
  }
}

# RDS 파라미터 그룹 (문자셋 설정)
resource "aws_db_parameter_group" "default" {
  name   = "${var.APP_NAME}-db-params"
  family = "mysql8.0"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }

  tags = {
    Name        = "${var.APP_NAME}-db-params"
    Environment = var.Environment
  }
}

# RDS 인스턴스 생성
resource "aws_db_instance" "mysql" {
  identifier        = "${var.APP_NAME}-${var.Environment}-mysql"
  engine            = "mysql"
  engine_version    = "8.0.41"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp2"
  username          = var.DB_USER
  password          = var.DB_PASSWORD
  db_name              = var.APP_NAME

  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  parameter_group_name   = aws_db_parameter_group.default.name

  # 개발환경 한정 퍼블릭 접근 허용
  multi_az             = true
  publicly_accessible = true
  skip_final_snapshot = true

  tags = {
    Name        = "${var.APP_NAME}-rds"
    Environment = var.Environment
  }
}
