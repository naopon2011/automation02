provider "aws" {
  region = var.aws_region
}

# VPCの作成
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = var.vpc_name,
    Tag = var.vpc_name
  }
}

# パブリックサブネットの作成
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = var.az1_name
  tags = {
    Name = "${var.vpc_name}-public-subnet"
  }
}

# パブリックサブネット用ルートテーブルの作成
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.vpc_name}-public-route-table"
  }
}

# Zscalerリソース用プライベートサブネットの作成
resource "aws_subnet" "private_subnet1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = var.az1_name
  tags = {
    Name = "${var.vpc_name}-private-subnet1"
  }
}

# CC送信元用プライベートサブネットの作成
resource "aws_subnet" "private_subnet2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = var.az1_name
  tags = {
    Name = "${var.vpc_name}-private-subnet2"
  }
}

# インターネットゲートウェイの作成
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

# デフォルトルートをインターネットゲートウェイに設定
resource "aws_route" "public_default_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_igw.id
}

#NATゲートウェイの作成
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public_subnet.id
  tags = {
    Name = "${var.vpc_name}-nat-gateway"
  }
}

# Elastic IPの作成
resource "aws_eip" "eip" {
  vpc = true
  tags = {
    Name = "${var.vpc_name}-eip"
  }
}

# パブリックサブネットにルートテーブルを紐づける
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# Zscalerリソース用プライベートサブネットのルートテーブルの作成
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }
}

# CC送信元用プライベートサブネットのルートテーブルの作成
resource "aws_route_table" "private_route_table2" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = module.cc_vm[0].id
  }
}

# プライベートサブネットにルートテーブルを紐づける
resource "aws_route_table_association" "private_subnet_association" {
  subnet_id      = aws_subnet.private_subnet1.id
  route_table_id = aws_route_table.private_route_table.id
}

# プライベートサブネットにルートテーブルを紐づける
resource "aws_route_table_association" "private_subnet_association2" {
  subnet_id      = aws_subnet.private_subnet2.id
  route_table_id = aws_route_table.private_route_table2.id
}

resource "aws_security_group" "sg" {
  # ... other configuration ...

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

#Windows Serverの作成
resource "aws_instance" "windows" {
  ami           = var.win_ami
  instance_type = var.win_instance_type
  subnet_id = aws_subnet.private_subnet2.id
  key_name = var.instance_key
  tags = {
    Name = "${var.vpc_name}-win"
  }
}
