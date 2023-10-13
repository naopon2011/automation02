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
module "cc_vm" {
  source                    = "./modules/terraform-zscc-ccvm-aws"
  cc_count                  = var.cc_count
  ami_id                    = "ami-0854c366a1edc5c3a"
  mgmt_subnet_id            = aws_subnet.private_subnet1.id
  service_subnet_id         = aws_subnet.private_subnet1.id
  instance_key              = "zsdemo"
  user_data                 = base64encode(local.userdata)
  ccvm_instance_type        = "t3.medium"
  iam_instance_profile      = module.cc_iam.iam_instance_profile_id
#  mgmt_security_group_id    = module.cc_sg.mgmt_security_group_id
#  service_security_group_id = module.cc_sg.service_security_group_id

}

locals {
  userdata = <<USERDATA
[ZSCALER]
CC_URL=${var.cc_vm_prov_url}
SECRET_NAME=${var.secret_name}
HTTP_PROBE_PORT=${var.http_probe_port}
USERDATA
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

