# IAM ROLE 생성
resource "aws_iam_role" "execution_role" {
  name               = "${var.APP_NAME}-${var.Environment}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  tags = {
    Name        = "${var.APP_NAME}-ecs-role"
    Environment = var.Environment
  }
}

# SQS 전송 권한
resource "aws_iam_policy" "sqs_access" {
  name = "${var.APP_NAME}-${var.Environment}-sqs-access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = [
        "sqs:SendMessage",        # 메시지 전송 (모든 서버 필요)
        "sqs:ReceiveMessage",     # 메시지 수신
        "sqs:DeleteMessage",      # 수신 후 삭제
        "sqs:GetQueueAttributes"  # 큐 속성 조회 (수신 쪽에서 주로 필요)
      ],
      Resource = "*"  # 또는 특정 SQS ARN으로 제한 가능
    }]
  })
}

# RDS 권한 (보통 연결만 하므로 EC2 권한으로 처리)
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

# S3 사용자 프로필 버킷 접근 권한
resource "aws_iam_policy" "s3_user_profile_access" {
  name = "${var.APP_NAME}-${var.Environment}-s3-access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        Resource = "arn:aws:s3:::couponmoa-user-profile-prod/*"
      }
    ]
  })
}

resource "aws_iam_policy" "terraform_lock_dynamodb_access" {
  name = "terraform-dynamodb-lock-access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:UpdateItem"
        ],
        Resource = "arn:aws:dynamodb:ap-northeast-2:588738590244:table/terraform-lock"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "attach_lock_policy" {
  user       = "couponmoa-accessuser"
  policy_arn = aws_iam_policy.terraform_lock_dynamodb_access.arn
}

# IAM ROLE에 SQS 정책 추가
resource "aws_iam_role_policy_attachment" "attach_sqs_policy" {
  role       = aws_iam_role.execution_role.name
  policy_arn = aws_iam_policy.sqs_access.arn
}

# IAM ROLE에 RDS 정책 추가
resource "aws_iam_role_policy_attachment" "attach_rds_policy" {
  role       = aws_iam_role.execution_role.name
  policy_arn = aws_iam_policy.rds_access.arn
}

# IAM ROLE에 Redis 정책(ElasticCache) 추가
resource "aws_iam_role_policy_attachment" "attach_redis_policy" {
  role       = aws_iam_role.execution_role.name
  policy_arn = aws_iam_policy.redis_access.arn
}

# IAM ROLE에 S3 접근 권한 정책 추가
resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.execution_role.name
  policy_arn = aws_iam_policy.s3_user_profile_access.arn
}

# IAM Role 권한 허가
# ECS Task가 IAM ROLE을 사용하도록 허용
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

# ECS Task AWS 자원 접근 허가
resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
