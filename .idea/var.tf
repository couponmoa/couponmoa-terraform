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

variable "DB_USER" {}
variable "DB_PASSWORD" {}
