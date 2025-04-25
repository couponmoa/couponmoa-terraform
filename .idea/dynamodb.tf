# dynamodb.tf

resource "aws_dynamodb_table" "terraform_lock_table" {
  name         = "terraform-lock"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "LockID"
    type = "S"
  }

  hash_key = "LockID"

  tags = {
    Name        = "Terraform Lock Table"
    Environment = var.Environment
  }
}