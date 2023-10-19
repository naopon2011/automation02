resource "random_string" "suffix" {
  length  = 8
  upper   = false
  special = false
}

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
  cc_count                  = 1
  ami_id                    = "ami-0854c366a1edc5c3a"
  mgmt_subnet_id            = aws_subnet.private_subnet1.id
  service_subnet_id         = aws_subnet.private_subnet1.id
  instance_key              = "zsdemo"
  user_data                 = local.userdata
  ccvm_instance_type        = "t3.medium"
  iam_instance_profile      = module.cc_iam.iam_instance_profile_id
  mgmt_security_group_id    = aws_security_group.sg.id
  service_security_group_id = aws_security_group.sg.id
}

module "cc_iam" {
  source              = "./modules/terraform-zscc-iam-aws"
  iam_count           = 1
  name_prefix         = var.name_prefix
  resource_tag        = random_string.suffix.result
  cc_callhome_enabled = var.cc_callhome_enabled
  secret_name         = var.secret_name
}
