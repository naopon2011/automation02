terraform {
  required_providers {
    zpa = {
      source = "zscaler/zpa"
      version = "~> 3.0.0"
    }
  }
}
provider "zpa" {
  zpa_client_id         =  "MjE2MTk5NjIxMzY0NDE2OTEzLWU1M2ExZTAyLTZiMzgtNDE3ZC1hMzY1LWM5YjZkN2UxNGI4Ng=="
  zpa_client_secret     =  "5X:/3WkjKAO?]<4T%!]`iD!9*SG.GkNl"
  zpa_customer_id       =  "216199621364416512"
}

// Create Application Segment
resource "zpa_application_segment" "crm_application" {
  name             = "CRM Application"
  description      = "CRM Application"
  enabled          = true
  health_reporting = "ON_ACCESS"
  bypass_type      = "NEVER"
  is_cname_enabled = true
  tcp_port_ranges  = ["80", "80"]
  domain_names     = ["crm.example.com"]
  segment_group_id = zpa_segment_group.crm_app_group.id
  server_groups {
    id = [zpa_server_group.crm_servers.id]
  }
}

// Create Server Group
resource "zpa_server_group" "crm_servers" {
  name              = "CRM Servers"
  description       = "CRM Servers"
  enabled           = true
  dynamic_discovery = false
  app_connector_groups {
    id = [data.zpa_app_connector_group.dc_connector_group.id]
  }
  servers {
    id = [zpa_application_server.crm_app_server.id]
  }
}

// Create Application Server
resource "zpa_application_server" "crm_app_server" {
  name        = "CRM App Server"
  description = "CRM App Server"
  address     = "crm.example.com"
  enabled     = true
}

// Create Segment Group
resource "zpa_segment_group" "crm_app_group" {
  name            = "CRM App group"
  description     = "CRM App group"
  enabled         = true
  policy_migrated = true
}

// Retrieve App Connector Group
data "zpa_app_connector_group" "dc_connector_group" {
  name = "SGIO-Vancouver"
}

provider "aws" {
  region = "ap-northeast-1"
}

variable "vpc_name" {
  description = "VPCの名前"
  type        = string
}
variable "provision_key" {
  description = "プロビジョンキーの名前"
  type        = string
}

# VPCタグ
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = var.vpc_name
  }
}
# パブリックサブネットタグ
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "ap-northeast-1a"
  tags = {
    Name = "${var.vpc_name}-public-subnet"
  }
}

# パブリックサブネット用ルートテーブルタグ
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.vpc_name}-public-route-table"
  }
}

# プライベートサブネットタグ
resource "aws_subnet" "private_subnet1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-northeast-1a"
  tags = {
    Name = "${var.vpc_name}-private-subnet1"
  }
}
resource "aws_subnet" "private_subnet2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-northeast-1c"
  tags = {
    Name = "${var.vpc_name}-private-subnet2"
  }
}

# インターネットゲートウェイタグ
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

#NATゲートウェイタグ
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public_subnet.id
  tags = {
    Name = "${var.vpc_name}-nat-gateway"
  }
}

# Elastic IPタグ
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

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }
}

resource "aws_route_table_association" "private_subnet_association" {
  subnet_id      = aws_subnet.private_subnet1.id
  route_table_id = aws_route_table.private_route_table.id
}

locals {
  command = <<EOF
#!/bin/bash
#Stop the App Connector service which was auto-started at boot time
systemctl stop zpa-connector
#Create a file from the App Connector provisioning key created in the ZPA Admin Portal
#Make sure that the provisioning key is between double quotes
echo "${var.provision_key}" > /opt/zscaler/var/provision_key
#Run a yum update to apply the latest patches
yum update -y
#Start the App Connector service to enroll it in the ZPA cloud
systemctl start zpa-connector
#Wait for the App Connector to download latest build
sleep 60
#Stop and then start the App Connector for the latest build
systemctl stop zpa-connector
systemctl start zpa-connector
   EOF
}

resource "aws_instance" "example" {
  ami           = "ami-05b60713705a935c2"
  instance_type = "t3.medium" 
  subnet_id = aws_subnet.private_subnet1.id
  user_data = base64encode(local.command)
  key_name = "zsdemo"
  tags = {
    Name = "${var.vpc_name}-ec2"
  }
}


