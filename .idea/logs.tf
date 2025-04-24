resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/${var.APP_NAME}"
  retention_in_days = 7

  tags = {
    Name        = "${var.APP_NAME}-log-group"
    Environment = var.Environment
  }
}