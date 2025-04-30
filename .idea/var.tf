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

variable ubuntu_ami_id {}


variable "msa_services" {
  default = ["user", "store", "coupon", "notification", "scheduling"]
}

variable "DB_USER" {}
variable "DB_PASSWORD" {}
variable "jwt_secret_key" {}
variable "rds_url" {}
variable "SMTP_USERNAME" {}
variable "SMTP_PASSWORD" {}
variable "google_api_key" {}
variable "key_name" {}