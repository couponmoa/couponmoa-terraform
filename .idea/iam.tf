# -------------------------
# 공통 Assume Role Policy
# -------------------------
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# -------------------------
# ECS Execution Role (for ECS 시스템용)
# -------------------------
resource "aws_iam_role" "execution_role" {
  name               = "${var.APP_NAME}-${var.Environment}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  tags = {
    Name        = "${var.APP_NAME}-ecs-execution-role"
    Environment = var.Environment
  }
}

# Execution Role에 AmazonECSTaskExecutionRolePolicy 붙이기 (필수)
resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# -------------------------
# ECS Task Role (for App 컨테이너용)
# -------------------------
resource "aws_iam_role" "task_role" {
  name               = "${var.APP_NAME}-${var.Environment}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  tags = {
    Name        = "${var.APP_NAME}-ecs-task-role"
    Environment = var.Environment
  }
}

# -------------------------
# 정책들 생성
# -------------------------

# SQS 전송 권한
resource "aws_iam_policy" "sqs_access" {
  name = "${var.APP_NAME}-${var.Environment}-sqs-access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = [
        "sqs:SendMessage",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      Resource = "*"
    }]
  })
}

# RDS 권한
resource "aws_iam_policy" "rds_access" {
  name = "${var.APP_NAME}-${var.Environment}-rds-access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = [
        "rds:DescribeDBInstances",
        "rds:DescribeDBClusters"
      ],
      Resource = "*"
    }]
  })
}

# Redis (ElastiCache) 권한
resource "aws_iam_policy" "redis_access" {
  name = "${var.APP_NAME}-${var.Environment}-redis-access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = [
        "elasticache:DescribeCacheClusters",
        "elasticache:ListTagsForResource"
      ],
      Resource = "*"
    }]
  })
}

# S3 접근 권한
resource "aws_iam_policy" "s3_user_profile_access" {
  name = "${var.APP_NAME}-${var.Environment}-s3-access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      Resource = "arn:aws:s3:::couponmoa-user-profile-prod/*"
    }]
  })
}

# -------------------------
# 정책 Attach (Task Role & Execution Role 둘 다)
# -------------------------

# --- Task Role Attach ---
resource "aws_iam_role_policy_attachment" "task_role_attach_sqs" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.sqs_access.arn
}

resource "aws_iam_role_policy_attachment" "task_role_attach_rds" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.rds_access.arn
}

resource "aws_iam_role_policy_attachment" "task_role_attach_redis" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.redis_access.arn
}

resource "aws_iam_role_policy_attachment" "task_role_attach_s3" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.s3_user_profile_access.arn
}

# --- Execution Role Attach ---
resource "aws_iam_role_policy_attachment" "execution_role_attach_sqs" {
  role       = aws_iam_role.execution_role.name
  policy_arn = aws_iam_policy.sqs_access.arn
}

resource "aws_iam_role_policy_attachment" "execution_role_attach_rds" {
  role       = aws_iam_role.execution_role.name
  policy_arn = aws_iam_policy.rds_access.arn
}

resource "aws_iam_role_policy_attachment" "execution_role_attach_redis" {
  role       = aws_iam_role.execution_role.name
  policy_arn = aws_iam_policy.redis_access.arn
}

resource "aws_iam_role_policy_attachment" "execution_role_attach_s3" {
  role       = aws_iam_role.execution_role.name
  policy_arn = aws_iam_policy.s3_user_profile_access.arn
}