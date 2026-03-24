output "nlb_arn" {
  description = "The ARN of the Network Load Balancer"
  value       = aws_lb.this.arn
}

output "nlb_dns_name" {
  description = "The DNS name of the Network Load Balancer"
  value       = aws_lb.this.dns_name
}

output "target_group_arn" {
  description = "The ARN of the target group (Attach the Workload ALB here)"
  value       = aws_lb_target_group.this.arn
}

output "nlb_private_ips" {
  description = "The private IP addresses of the NLB nodes"
  value       = data.aws_network_interface.nlb[*].private_ip
}