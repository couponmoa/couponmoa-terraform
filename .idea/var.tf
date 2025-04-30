variable "AWS_REGION" {
  default = "ap-northeast-2"
}

variable "AWS_ACCESS_KEY" {}
variable "AWS_SECRET_KEY" {}

variable "APP_NAME" {
  default = "couponmoa"
}

variable "Environment" {
  default = "dev"
}

variable "msa_services" {
  default = ["user", "store", "coupon", "notification", "scheduling"]
}

variable "enable_monitoring_sidecar" {
  description = "Enable the ADOT Collector sidecar for monitoring in MSA tasks"
  type        = bool
  default     = true # 기본적으로 활성화, 필요시 false로 변경하여 비활성화
}

variable "adot_image_tag" {
  description = "The Docker image tag for the custom ADOT Collector image in ECR"
  type        = string
  default     = "latest" # CI/CD 파이프라인에서 실제 태그로 전달받는 것이 좋음
}

variable "adot_image_uri" {
  description = "The ECR repository URI for the custom ADOT Collector image"
  type        = string
  # 기본값을 설정하거나, ecr.tf의 output을 참조하거나, CI/CD에서 전달받아야 함
  # ex default = "ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/couponmoa-dev-adot-collector-ecr"
}

variable "DB_USER" {}
variable "DB_PASSWORD" {}
variable "jwt_secret_key" {}
variable "rds_url" {}
variable "SMTP_USERNAME" {}
variable "SMTP_PASSWORD" {}
variable "google_api_key" {}
