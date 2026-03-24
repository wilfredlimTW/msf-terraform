# Outputs are commented out until the module is fully implemented.

/*
output "firewall_arn" {
  description = "The ARN of the Network Firewall"
  value       = aws_networkfirewall_firewall.this.arn
}

output "firewall_endpoint_ids" {
  description = "The endpoint IDs created by the firewall (critical for updating route tables later)"
  value       = aws_networkfirewall_firewall.this.endpoint_id
}
*/