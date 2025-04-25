# IAM Role for ECS Fargate Task Execution
resource "aws_iam_role" "execution_role" {
  name               = "${var.APP_NAME}-${var.Environment}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  tags = {
    Name        = "${var.APP_NAME}-ecs-role"
    Environment = var.Environment
  }
}

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

resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.execution_role.name
  policy_arn = aws_iam_policy.s3_user_profile_access.arn
}

# Assume Role Policy Document
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

# Attach the proper execution policy for Fargate
resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
