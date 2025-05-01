resource "aws_ecr_repository" "repository" {
  name = "${var.APP_NAME}-${var.Environment}-ecr"

  tags = {
    Name        = "${var.APP_NAME}-ecr"
    Environment = var.Environment
  }
}

resource "aws_ecr_repository" "msa_repos" {
  for_each = toset(var.msa_services)

  name = "${var.APP_NAME}-${var.Environment}-${each.key}-ecr"

  tags = {
    Name        = "${var.APP_NAME}-${each.key}-ecr"
    Environment = var.Environment
  }
}

resource "aws_ecr_repository" "ai" {
  name = "${var.APP_NAME}-${var.Environment}-ai-ecr"

  tags = {
    Name        = "${var.APP_NAME}-ai-ecr"
    Environment = var.Environment
  }
}

resource "aws_ecr_repository" "adot_collector" {
  name = "${var.APP_NAME}-${var.Environment}-adot-collector-ecr" 

  tags = {
    Name        = "${var.APP_NAME}-adot-collector-ecr"
    Environment = var.Environment
  }
}
