resource "aws_sqs_queue" "email_alert_queue" {
  name = "couponmoa-queue"

  visibility_timeout_seconds = 30
  message_retention_seconds  = 1209600

  tags = {
    Name        = "couponmoa-queue"
    Environment = var.Environment
  }
}

resource "aws_sqs_queue" "coupon_alert_queue" {
  name = "coupon-alert-queue"

  visibility_timeout_seconds = 30
  message_retention_seconds  = 1209600

  tags = {
    Name        = "coupon-alert-queue"
    Environment = var.Environment
  }
}
