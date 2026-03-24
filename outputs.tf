# outputs.tf
output "internet_alb_dns_url" {
  description = "The URL of the Internet-facing Application Load Balancer"
  value       = "http://${module.internet_alb.alb_dns_name}"
}