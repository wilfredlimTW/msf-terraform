output "cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.this.name
}

output "service_name" {
  description = "The name of the ECS service"
  value       = aws_ecs_service.this.name
}