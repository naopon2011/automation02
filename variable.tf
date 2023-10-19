variable "aws_region" {
  type        = string
  description = "AWSのリージョン"
  default     = "ap-northeast-1"
}

variable "vpc_name" {
  description = "VPCの名前"
  type        = string
}

variable "az1_name" {
  description = "一つ目のavailability zone"
  type        = string
  default     = "ap-northeast-1a"
}

variable "ac_ami" {
  description = "Cloud Connectorのami"
  type        = string
  default     = "ami-0854c366a1edc5c3a"
}

variable "ac_instance_type" {
  description = "Cloud Connectorのinstance type"
  type        = string
  default     = "t3.medium"
}

variable "cc_ami" {
  description = "Cloud Connectorのami"
  type        = string
  default     = "ami-0854c366a1edc5c3a"
}

variable "cc_instance_type" {
  description = "Cloud Connectorのinstance type"
  type        = string
  default     = "t3.medium"
}

variable "provision_key" {
  description = "App Connector用のProvisioning Keyの名前"
  type        = string
}

variable "name_prefix" {
  type        = string
  description = "The name prefix for all your resources"
  default     = "zscc"
  validation {
    condition     = length(var.name_prefix) <= 12
    error_message = "Variable name_prefix must be 12 or less characters."
  }
}

variable "cc_callhome_enabled" {
  type        = bool
  description = "determine whether or not to create the cc-callhome-policy IAM Policy and attach it to the CC IAM Role"
  default     = true
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
