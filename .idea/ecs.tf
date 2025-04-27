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
  task_role_arn            = aws_iam_role.task_role.arn

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
  cpu                     = "256"
  memory                  = "512"
  execution_role_arn      = aws_iam_role.execution_role.arn
  task_role_arn           = aws_iam_role.task_role.arn

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

// redis
resource "aws_ecs_task_definition" "redis_task" {
  family                   = "${var.APP_NAME}-${var.Environment}-redis"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name         = "${var.APP_NAME}-${var.Environment}-redis-container"
      image        = "redis:7.2"  # 최신 버전으로 사용
      essential    = true
      portMappings = [
        {
          containerPort = 6379
        }
      ]
      memory = 512
      cpu    = 256
    }
  ])

  tags = {
    Name        = "${var.APP_NAME}-redis-task"
    Environment = var.Environment
  }
}

resource "aws_ecs_service" "redis_service" {
  name                = "${var.APP_NAME}-${var.Environment}-redis-service"
  cluster             = aws_ecs_cluster.cluster.id
  task_definition     = aws_ecs_task_definition.redis_task.arn
  launch_type         = "FARGATE"
  desired_count       = 1
  scheduling_strategy = "REPLICA"

  network_configuration {
    subnets         = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
    security_groups = [aws_security_group.redis_sg.id]
    assign_public_ip = false
  }
}

# 오토스케일링 타겟 (서비스별로 하나씩)
resource "aws_appautoscaling_target" "msa_scaling_target" {
  for_each = toset(var.msa_services)

  max_capacity       = 5
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.msa_service[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# 오토스케일링 정책 (서비스별로 하나씩)
resource "aws_appautoscaling_policy" "msa_cpu_scaling_policy" {
  for_each = toset(var.msa_services)

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

