resource "aws_ecs_cluster" "cluster" {
  name = "${var.APP_NAME}-${var.Environment}-cluster"

  tags = {
    Name        = "${var.APP_NAME}-ecs"
    Environment = var.Environment
  }
}

// gateway server
// Task Definition 등록 (ECR 이미지 사용)
resource "aws_ecs_task_definition" "gateway_task" {
  family                   = "${var.APP_NAME}-gateway"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.execution_role.arn
  task_role_arn            = aws_iam_role.execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.APP_NAME}-${var.Environment}-container",
      image     = "${aws_ecr_repository.repository.repository_url}:latest",
      essential = true,
      cpu       = 256,
      memory    = 512,
      portMappings = [
        {
          containerPort = 3000
        }
      ],
      environment = [
        {
          name  = "SPRING_PROFILES_ACTIVE"
          value = "prod"
        },
        {
          name  = "JWT_SECRET_KEY"
          value = var.jwt_secret_key
        },
        {
          name  = "REDIS_HOST"
          value = "10.0.11.158"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.APP_NAME}"
          awslogs-region        = "ap-northeast-2"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.APP_NAME}-ecs-task"
    Environment = var.Environment
  }
}

data "aws_ecs_task_definition" "latest" {
  task_definition = aws_ecs_task_definition.gateway_task.family
}

resource "aws_ecs_service" "gateway_service" {
  name                = "${var.APP_NAME}-${var.Environment}-service"
  cluster             = aws_ecs_cluster.cluster.id
  task_definition     = "${aws_ecs_task_definition.gateway_task.family}:${max(aws_ecs_task_definition.gateway_task.revision, data.aws_ecs_task_definition.latest.revision)}"
  launch_type         = "FARGATE"
  scheduling_strategy = "REPLICA"
  desired_count       = 1

  network_configuration {
    subnets         = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = "${var.APP_NAME}-${var.Environment}-container"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.alb_listener]
}

// user, store, coupon, notification, scheduling 서버
resource "aws_ecs_task_definition" "msa_task" {
  for_each                = toset(var.msa_services)
  family                  = "${var.APP_NAME}-${each.key}"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = "512"
  memory                  = "1024"
  execution_role_arn      = aws_iam_role.execution_role.arn
  task_role_arn           = aws_iam_role.execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.APP_NAME}-${var.Environment}-${each.key}-container"
      image     = "${aws_ecr_repository.msa_repos[each.key].repository_url}:latest"
      essential = true
      cpu       = 256
      memory    = 512
      # portMappings = [
      #   {
      #     containerPort = lookup({ user = 8081, store = 8082, coupon = 8083, notification = 8084, scheduling = 8085 }, each.key)
      #
      #   }
      # ]
      portMappings = [
        {
          containerPort = lookup({ user = 8081, store = 8082, coupon = 8083, notification = 8084, scheduling = 8085 }, each.key)
          hostPort      = lookup({ user = 8081, store = 8082, coupon = 8083, notification = 8084, scheduling = 8085 }, each.key)
          protocol      = "tcp"
        },
        {
          containerPort = 6565
          hostPort      = 6565
          protocol      = "tcp"
        },
        {
          containerPort = 9090
          hostPort      = 9090
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "SPRING_PROFILES_ACTIVE"
          value = "prod"
        },
        {
          name  = "JWT_SECRET_KEY"
          value = var.jwt_secret_key
        },
        {
          name  = "REDIS_HOST"
          value = "10.0.11.158"
        },
        {
          name  = "RDS_URL"
          value = var.rds_url
        },
        {
          name  = "RDS_USERNAME"
          value = var.DB_USER
        },
        {
          name  = "RDS_PASSWORD"
          value = var.DB_PASSWORD
        },
        {
          name  = "SMTP_USERNAME"
          value = var.SMTP_USERNAME
        },
        {
          name  = "SMTP_PASSWORD"
          value = var.SMTP_PASSWORD
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.APP_NAME}"
          awslogs-region        = "ap-northeast-2"
          awslogs-stream-prefix = each.key
        }
      }
    },
// ADOT Collector 사이드카 컨테이너 정의 추가 ( 각서버의 log, metric 수집해서 AMP로 보내는 역할)
 {
      "name": "adot-collector",                            
      "image": "amazon/aws-otel-collector:latest",  // ADOT Collector 커스텀 이미지 빌드 및 푸시 이후에 변경되어야함. 
      "essential": true,                                  
      "cpu": 256,                                        
      "memory": 512,                                     
      "command": ["--config=/etc/otel/config.yaml"],
      "environment": [
        {
          "name": "AWS_REGION",
          "value": var.AWS_REGION                         
        },
        {
          "name": "AMP_REMOTE_WRITE_URL",
          "value": "${aws_prometheus_workspace.couponmoa_amp.prometheus_endpoint}api/v1/remote_write"
        }
      ],
      "logConfiguration": {
         "logDriver": "awslogs",
         "options": {
           "awslogs-group": "/ecs/${var.APP_NAME}",
           "awslogs-region": var.AWS_REGION,
           "awslogs-stream-prefix": "${each.key}-adot" 
         }
       }
    }
  ])

  tags = {
    Name        = "${var.APP_NAME}-${each.key}-task"
    Environment = var.Environment
  }
}

data "aws_ecs_task_definition" "msa_latest" {
  for_each = toset(var.msa_services)
  task_definition = aws_ecs_task_definition.msa_task[each.key].family
}

resource "aws_ecs_service" "msa_service" {
  for_each             = toset(var.msa_services)
  name                 = "${var.APP_NAME}-${var.Environment}-${each.key}-service"
  cluster              = aws_ecs_cluster.cluster.id
  task_definition      = "${aws_ecs_task_definition.msa_task[each.key].family}:${max(aws_ecs_task_definition.msa_task[each.key].revision, data.aws_ecs_task_definition.msa_latest[each.key].revision)}"
  launch_type          = "FARGATE"
  scheduling_strategy  = "REPLICA"
  desired_count        = 1

  network_configuration {
    subnets         = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.services[each.key].arn
    container_name = "${var.APP_NAME}-${var.Environment}-${each.key}-container"
  }
}

// ai 서버
resource "aws_ecs_task_definition" "ai_task" {
  family                   = "${var.APP_NAME}-ai"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.execution_role.arn
  task_role_arn            = aws_iam_role.execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.APP_NAME}-${var.Environment}-ai-container",
      image = "${aws_ecr_repository.ai.repository_url}:latest"
      essential = true,
      cpu       = 256,
      memory    = 512,
      portMappings = [
        {
          containerPort = 8086,
          hostPort      = 8086,
          protocol      = "tcp"
        }
      ],
      environment = [
        {
          name  = "SPRING_PROFILES_ACTIVE"
          value = "prod"
        },
        {
          name  = "GOOGLE_API_KEY"
          value = var.google_api_key
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = "/ecs/${var.APP_NAME}"
          awslogs-region        = var.AWS_REGION
          awslogs-stream-prefix = "ai"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.APP_NAME}-ai-task"
    Environment = var.Environment
  }
}

resource "aws_ecs_service" "ai_service" {
  name                 = "${var.APP_NAME}-${var.Environment}-ai-service"
  cluster              = aws_ecs_cluster.cluster.id
  task_definition      = aws_ecs_task_definition.ai_task.arn
  launch_type          = "FARGATE"
  desired_count        = 1
  scheduling_strategy  = "REPLICA"

  network_configuration {
    subnets         = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.ai.arn
    container_name = "${var.APP_NAME}-${var.Environment}-ai-container"
  }
}

resource "aws_prometheus_workspace" "couponmoa_amp" {
  alias = "couponmoa-workspace-${var.Environment}" 

  tags = {
    Name        = "${var.APP_NAME}-amp-workspace"
    Environment = var.Environment
    Project     = "CouponMoa"
  }
}

locals {
  scalable_services = [for svc in var.msa_services : svc if !(svc == "notification" || svc == "scheduling" || svc == "ai")]
}

# 오토스케일링 타겟 (user, store, coupon만)
resource "aws_appautoscaling_target" "msa_scaling_target" {
  for_each = toset(local.scalable_services)

  max_capacity       = 5
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.msa_service[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# 오토스케일링 정책 (user, store, coupon만)
resource "aws_appautoscaling_policy" "msa_cpu_scaling_policy" {
  for_each = toset(local.scalable_services)

  name               = "${each.key}-cpu-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.msa_scaling_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.msa_scaling_target[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.msa_scaling_target[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 50.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

