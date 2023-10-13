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

resource "aws_security_group" "sg" {
  # ... other configuration ...

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app_connector" {
  ami           = "ami-05b60713705a935c2"
  instance_type = "t3.medium" 
  subnet_id = aws_subnet.private_subnet1.id
  user_data = base64encode(local.command)
  key_name = "zsdemo"
  tags = {
    Name = "${var.vpc_name}-ec2"
  }
}






resource "random_string" "suffix" {
  length  = 8
  upper   = false
  special = false
}

################################################################################
# Create Cloud Connector VM
################################################################################
#resource "aws_instance" "cc_vm" {
#  count                       = 1
#  ami                         = "ami-0854c366a1edc5c3a"
#  instance_type               = "t3.medium"
#  iam_instance_profile        = element(var.iam_instance_profile, count.index)
# # iam_instance_profile        = module.cc_iam.iam_instance_profile_id
# # vpc_security_group_ids      = [element(var.mgmt_security_group_id, count.index)]
#  subnet_id                   = aws_subnet.private_subnet1.id
#  key_name                    = "zsdemo"
#  associate_public_ip_address = false
#  user_data                   = base64encode(local.userdata)

 # metadata_options {
#    http_endpoint = "enabled"
##    http_tokens   = var.imdsv2_enabled ? "required" : "optional"
#  }
#}


locals {
  userdata = <<USERDATA
[ZSCALER]
CC_URL=${var.cc_vm_prov_url}
SECRET_NAME=${var.secret_name}
HTTP_PROBE_PORT=${var.http_probe_port}
USERDATA
}

module "cc_vm" {
  source                    = "./modules/terraform-zscc-ccvm-aws"
#  cc_count                  = var.cc_count
  cc_count                  = 1
  ami_id                    = "ami-0854c366a1edc5c3a"
  mgmt_subnet_id            = aws_subnet.public_subnet.id
  service_subnet_id         = aws_subnet.public_subnet.id
  instance_key              = "zsdemo"
 # user_data                 = base64encode(local.userdata)
  user_data                 = local.userdata
  ccvm_instance_type        = "t3.medium"
  iam_instance_profile      = module.cc_iam.iam_instance_profile_id
#  mgmt_security_group_id    = module.cc_sg.mgmt_security_group_id
#  service_security_group_id = module.cc_sg.service_security_group_id
   mgmt_security_group_id    = aws_security_group.sg.id
  service_security_group_id = aws_security_group.sg.id
}


variable "cc_vm_prov_url" {
  type        = string
  description = "Zscaler Cloud Connector Provisioning URL"
}

variable "secret_name" {
  type        = string
  description = "AWS Secrets Manager Secret Name for Cloud Connector provisioning"
}

variable "http_probe_port" {
  type        = number
  description = "Port number for Cloud Connector cloud init to enable listener port for HTTP probe from GWLB Target Group"
  default     = 50000
  validation {
    condition = (
      tonumber(var.http_probe_port) == 80 ||
      (tonumber(var.http_probe_port) >= 1024 && tonumber(var.http_probe_port) <= 65535)
    )
    error_message = "Input http_probe_port must be set to a single value of 80 or any number between 1024-65535."
  }
}

module "cc_iam" {
  source              = "./modules/terraform-zscc-iam-aws"
  iam_count           = 1
  name_prefix         = var.name_prefix
  resource_tag        = random_string.suffix.result
#  global_tags         = local.global_tags
  cc_callhome_enabled = var.cc_callhome_enabled
  secret_name         = var.secret_name
}
