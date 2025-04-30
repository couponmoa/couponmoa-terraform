resource "aws_service_discovery_private_dns_namespace" "namespace" {
  name = "couponmoa.local"
  vpc  = aws_vpc.vpc.id
  description = "Private namespace for service discovery"
}

resource "aws_service_discovery_service" "services" {
  for_each = toset(var.msa_services)

  name = "${var.APP_NAME}-${var.Environment}-${each.key}-service"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.namespace.id
    dns_records {
      type = "A"
      ttl  = 10
    }
    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_service_discovery_service" "ai" {
  name = "${var.APP_NAME}-${var.Environment}-ai-service"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.namespace.id
    dns_records {
      type = "A"
      ttl  = 10
    }
    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags = {
    Name        = "${var.APP_NAME}-ai-discovery"
    Environment = var.Environment
  }
}