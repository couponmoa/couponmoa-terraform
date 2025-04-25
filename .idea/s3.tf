resource "aws_s3_bucket" "image_bucket" {
  bucket = "couponmoa-user-profile-prod"
  force_destroy = true

  tags = {
    Name        = "couponmoa-user-profile-prod"
    Environment = var.Environment
  }
}

resource "aws_s3_bucket_public_access_block" "image_bucket_block" {
  bucket = aws_s3_bucket.image_bucket.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "image_bucket_policy" {
  bucket = aws_s3_bucket.image_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # CloudFront에 대한 GetObject 허용
      {
        Sid       = "AllowCloudFrontServicePrincipalReadOnly",
        Effect    = "Allow",
        Principal = {
          Service = "cloudfront.amazonaws.com"
        },
        Action = "s3:GetObject",
        Resource = "${aws_s3_bucket.image_bucket.arn}/*",
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.cdn.arn
          }
        }
      },
      # IAM Role (ECS Task)에 대한 접근 허용
      {
        Sid       = "AllowEcsTaskRoleAccess",
        Effect    = "Allow",
        Principal = {
          AWS = aws_iam_role.execution_role.arn
        },
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        Resource = "${aws_s3_bucket.image_bucket.arn}/*"
      }
    ]
  })
}
