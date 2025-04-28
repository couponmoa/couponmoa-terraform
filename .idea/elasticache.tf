# Elasticache Subnet Group (프라이빗 서브넷에 연결)
resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "${var.APP_NAME}-${var.Environment}-redis-subnet-group"
  subnet_ids = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ]

  tags = {
    Name        = "${var.APP_NAME}-redis-subnet-group"
    Environment = var.Environment
  }
}

# Elasticache Redis 클러스터 생성
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.APP_NAME}-${var.Environment}-redis"
  engine               = "redis"
  engine_version       = "7.0"
  node_type            = "cache.t4g.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379

  subnet_group_name    = aws_elasticache_subnet_group.redis_subnet_group.name
  security_group_ids   = [aws_security_group.redis_sg.id]

  tags = {
    Name        = "${var.APP_NAME}-redis"
    Environment = var.Environment
  }
}
