resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.APP_NAME}-vpc"
    Environment = var.Environment
  }
}

# 퍼블릭 서브넷
resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "${var.AWS_REGION}a"

  tags = {
    Name        = "${var.APP_NAME}-public-subnet-1"
    Environment = var.Environment
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.AWS_REGION}c"

  tags = {
    Name        = "${var.APP_NAME}-public-subnet-2"
    Environment = var.Environment
  }
}

# 프라이빗 서브넷
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "${var.AWS_REGION}a"

  tags = {
    Name        = "${var.APP_NAME}-private-subnet-1"
    Environment = var.Environment
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "${var.AWS_REGION}c"

  tags = {
    Name        = "${var.APP_NAME}-private-subnet-2"
    Environment = var.Environment
  }
}

# 인터넷 게이트웨이
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name        = "${var.APP_NAME}-igw"
    Environment = var.Environment
  }
}

# 퍼블릭 라우트 테이블 + 연결
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name        = "${var.APP_NAME}-public-rt"
    Environment = var.Environment
  }
}

resource "aws_route_table_association" "public_route_table_association_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_route_table_association_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

# 프라이빗 라우트 테이블 (NAT 없이 기본 설정)
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name        = "${var.APP_NAME}-private-rt"
    Environment = var.Environment
  }
}

resource "aws_route_table_association" "private_route_table_association_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_route_table_association_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table.id
}

# VPC Endpoint: S3
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${var.AWS_REGION}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private_route_table.id]
}

# VPC Endpoint: SQS
resource "aws_vpc_endpoint" "sqs" {
  vpc_id             = aws_vpc.vpc.id
  service_name       = "com.amazonaws.${var.AWS_REGION}.sqs"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  security_group_ids = [var.endpoint_sg_id]
  private_dns_enabled = true
}

# VPC Endpoint: ECR API (Interface)
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id             = aws_vpc.vpc.id
  service_name       = "com.amazonaws.${var.AWS_REGION}.ecr.api"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  security_group_ids = [var.endpoint_sg_id]
  private_dns_enabled = true
}

# VPC Endpoint: ECR DKR (Interface)
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id             = aws_vpc.vpc.id
  service_name       = "com.amazonaws.${var.AWS_REGION}.ecr.dkr"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  security_group_ids = [var.endpoint_sg_id]
  private_dns_enabled = true
}