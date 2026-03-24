output "internet_alb_sg_id" {
  value = aws_security_group.internet_alb.id
}

output "workload_nlb_sg_id" {
  value = aws_security_group.workload_nlb.id
}

output "workload_alb_sg_id" {
  value = aws_security_group.workload_alb.id
}

output "ecs_tasks_sg_id" {
  value = aws_security_group.ecs_tasks.id
}

output "aurora_db_sg_id" {
  value = aws_security_group.aurora_db.id
}