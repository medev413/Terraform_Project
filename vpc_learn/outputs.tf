output "public_ip" {
  value = aws_instance.EC2-public.public_ip
}

output "lb_dns_resolver" {
  value = aws_lb.load_balancer.dns_name
}