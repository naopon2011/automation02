output "security_group" {
  value       = aws_instance.cc_vm[*].availability_zone
}
output "private_subnet" {
  value       = aws_instance.cc_vm[*].availability_zone
}
