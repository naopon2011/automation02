################################################################################
# Create Cloud Connector VM
################################################################################
resource "aws_instance" "cc_vm" {
  count                       = 1
  ami                         = ami-0854c366a1edc5c3a
  instance_type               = t3.medium
 # iam_instance_profile        = element(var.iam_instance_profile, count.index)
 # vpc_security_group_ids      = [element(var.mgmt_security_group_id, count.index)]
  subnet_id                   = aws_subnet.private_subnet1.id
  key_name                    = "zsdemo"
  associate_public_ip_address = false
  user_data                   = base64encode(var.user_data)

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = var.imdsv2_enabled ? "required" : "optional"
  }

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-cc-vm-${count.index + 1}-${var.resource_tag}" }
  )
}


################################################################################
# Create Cloud Connector Service Interface for Small CC. 
# This interface becomes LB0 interface for Medium/Large size CCs
################################################################################
resource "aws_network_interface" "cc_vm_nic_index_1" {
  count             = local.valid_cc_create ? var.cc_count : 0
  description       = var.cc_instance_size == "small" ? "Primary Interface for service traffic" : "CC Med/Lrg LB interface"
  subnet_id         = element(var.service_subnet_id, count.index)
  security_groups   = [element(var.service_security_group_id, count.index)]
  source_dest_check = false
  private_ips_count = 1
  attachment {
    instance     = aws_instance.cc_vm[count.index].id
    device_index = 1
  }

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-cc-vm-${count.index + 1}-${var.resource_tag}-SrvcIF1" }
  )
}
