output "public_ip" {
  description = "*****"
  value = aws_instance.ec2.public_ip
}

output "security_group_id" {
  description = "***"
  value = aws_instance.ec2.security_groups
}
