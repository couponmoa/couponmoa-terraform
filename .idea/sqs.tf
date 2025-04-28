resource "aws_sqs_queue" "coupon_create_queue" {
  name = "coupon-create-queue"

  visibility_timeout_seconds = 30
  message_retention_seconds  = 1209600

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount = 10
  })

  tags = {
    Name        = "coupon-create-queue"
    Environment = var.Environment
  }
}

resource "aws_sqs_queue" "coupon_issue_v1_queue" {
  name = "coupon-issue-v1-queue"

  visibility_timeout_seconds = 30
  message_retention_seconds  = 1209600

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount = 10
  })

  tags = {
    Name        = "couponmoa-issue-v1-queue"
    Environment = var.Environment
  }
}

resource "aws_sqs_queue" "coupon_issue_v2_queue" {
  name = "coupon-issue-v2-queue"

  visibility_timeout_seconds = 30
  message_retention_seconds  = 1209600

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount = 10
  })

  tags = {
    Name        = "coupon-issue-v2-queue"
    Environment = var.Environment
  }
}

resource "aws_sqs_queue" "coupon_expire_queue" {
  name = "coupon-expire-queue"

  visibility_timeout_seconds = 30
  message_retention_seconds  = 1209600

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount = 10
  })

  tags = {
    Name        = "coupon-expire-queue"
    Environment = var.Environment
  }
}

resource "aws_sqs_queue" "coupon_use_queue" {
  name = "coupon-use-queue"

  visibility_timeout_seconds = 30
  message_retention_seconds  = 1209600

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount = 10
  })

  tags = {
    Name        = "coupon-use-queue"
    Environment = var.Environment
  }
}

resource "aws_sqs_queue" "dead_letter_queue" {
  name = "dead-letter-queue"

  visibility_timeout_seconds = 30
  message_retention_seconds  = 1209600

  tags = {
    Name        = "dead-letter-queue"
    Environment = var.Environment
  }
}

resource "aws_sqs_queue_redrive_allow_policy" "couponmoa_queue_redrive_allow_policy" {
  queue_url = aws_sqs_queue.dead_letter_queue.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns = [
      aws_sqs_queue.coupon_create_queue.arn,
      aws_sqs_queue.coupon_expire_queue.arn,
      aws_sqs_queue.coupon_issue_v1_queue.arn,
      aws_sqs_queue.coupon_issue_v2_queue.arn,
      aws_sqs_queue.coupon_use_queue.arn
    ]
  })

}