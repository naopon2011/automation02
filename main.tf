provider "aws" {
  region = "ap-northeast-1"
}

variable "vpc_name" {
  description = "VPCの名前"
  type        = string
}
# VPCタグ
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = var.vpc_name
  }
}
# パブリックサブネットタグ
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "ap-northeast-1a"
  tags = {
    Name = "${var.vpc_name}-public-subnet"
  }
}
