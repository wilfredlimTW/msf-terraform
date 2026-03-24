output "cluster_endpoint" {
  description = "The cluster endpoint for read/write operations"
  value       = aws_rds_cluster.this.endpoint
}

output "reader_endpoint" {
  description = "The reader endpoint for read-only operations"
  value       = aws_rds_cluster.this.reader_endpoint
}

output "master_user_secret_arn" {
  description = "The ARN of the secret containing the master user credentials"
  value       = aws_rds_cluster.this.master_user_secret[0].secret_arn
}