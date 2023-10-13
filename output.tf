output "security_group" {
  value       = aws_security_group.sg.id
}
output "private_subnet" {
  value       = aws_subnet.public_subnet.id
}
