variable "environment" {
  description = "The environment name"
  type        = string
}

variable "subnet_ids" {
  description = "List of App Subnet IDs in the Workload VPC for the ECS tasks"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of Security Group IDs for the ECS tasks"
  type        = list(string)
}

variable "target_group_arn" {
  description = "The ARN of the Workload ALB Target Group"
  type        = string
}

variable "container_image" {
  description = "The container image to run"
  type        = string
  default     = "k8s.gcr.io/e2e-test-images/echoserver:2.5"
}