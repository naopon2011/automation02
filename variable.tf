variable "aws_region" {
  type        = string
  description = "AWSのリージョン"
  default     = "ap-northeast-1"
}

variable "vpc_name" {
  description = "VPCの名前"
  type        = string
}

variable "vpc_cidr" {
  description = "VPCで使用するアドレス帯"
  type        = string
  default     = "10.0.0.0/16"
}

variable "pub_subnet_cidr" {
  description = "パブリックサブネットで使用するアドレス帯"
  type        = string
  default     = "10.0.0.0/24"
}

variable "pri1_subnet_cidr" {
  description = "プライベートサブネット１で使用するアドレス帯"
  type        = string
  default     = "10.0.1.0/24"
}

variable "pri2_subnet_cidr" {
  description = "プライベートサブネット2で使用するアドレス帯"
  type        = string
  default     = "10.0.2.0/24"
}

variable "az1_name" {
  description = "一つ目のavailability zone"
  type        = string
  default     = "ap-northeast-1a"
}

variable "instance_key" {
  description = "インスタンス接続用のシークレットキー名"
  type        = string
}

variable "win_ami" {
  description = "Windows(踏み台用)のami(踏み台用)"
  type        = string
  default     = "ami-0962657fe505b0123"
}

variable "win_instance_type" {
  description = "Windows(踏み台用)のinstance type"
  type        = string
  default     = "t2.micro"
}

variable "ac_ami" {
  description = "App Connectorのami"
  type        = string
  default     = "ami-05b60713705a935c2"
}

variable "ac_instance_type" {
  description = "App Connectorのinstance type"
  type        = string
  default     = "t3.medium"
}

variable "zpa_client_id" {
  type        = string
  description = "Zscaler Private Access Client ID"
  sensitive   = true
}

variable "zpa_client_secret" {
  type        = string
  description = "Zscaler Private Access Secret ID"
  sensitive   = true
}

variable "zpa_customer_id" {
  type        = string
  description = "Zscaler Private Access Tenant ID"
}

variable "ac_group" {
  type        = string
  description = "App Connector Groupの名前"
}

variable "provision_key" {
  description = "App Connector用のProvisioning Keyの名前"
  type        = string
}
