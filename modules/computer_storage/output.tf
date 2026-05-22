output "vpc_id" {
  value       = aws_vpc.main.id
  description = "The ID of the provisioned VPC"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "IDs of the public subnets"
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "IDs of the private subnets"
}

output "alb_dns_name" {
  value       = aws_lb.external_alb.dns_name
  description = "The public URL of your application load balancer. Use this to test the deployment!"
}