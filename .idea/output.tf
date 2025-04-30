# ALB DNS (외부 접근 테스트용)
output "load_balancer_dns" {
  description = "ALB 주소 (Route 53 또는 직접 접속용)"
  value       = aws_lb.alb.dns_name
}

# ECS 클러스터 이름
output "ecs_cluster_name" {
  description = "ECS 클러스터 이름"
  value       = aws_ecs_cluster.cluster.name
}

# ECR 리포지토리 URL
output "ecr_repository_url" {
  description = "ECR에 push할 때 사용하는 리포지토리 주소"
  value       = aws_ecr_repository.repository.repository_url
}

# RDS 접속 주소
output "rds_endpoint" {
  description = "MySQL 접속용 RDS 엔드포인트"
  value       = aws_db_instance.mysql.endpoint
}

# VPC ID
output "vpc_id" {
  description = "VPC ID (참조용)"
  value       = aws_vpc.vpc.id
}

# ECS service arn
output "msa_service_ids" {
  value = {
    for name, svc in aws_ecs_service.msa_service :
    name => svc.id
  }
}

# ai service dns
output "ai_service_discovery_dns" {
  value = "${aws_service_discovery_service.ai.name}.${aws_service_discovery_private_dns_namespace.namespace.name}"
  description = "ai-server의 Cloud Map 내부 DNS 주소"
}

# s3 버킷 이름
output "s3_bucket_name" {
  value = aws_s3_bucket.image_bucket.id
}

# cloudfront 도메인
output "cloudfront_domain_name" {
  value       = aws_cloudfront_distribution.cdn.domain_name
}

# sqs queue url
output "sqs_queue_urls" {
  value = {
    email_alert  = aws_sqs_queue.email_alert_queue.url
    coupon_alert = aws_sqs_queue.coupon_alert_queue.url
  }
}

# Elasticache Redis 엔드포인트 출력
output "elasticache_redis_endpoint" {
  description = "Elasticache Redis primary endpoint"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "elasticache_redis_port" {
  description = "Elasticache Redis port"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].port
}
