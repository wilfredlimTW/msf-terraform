variable "alb_name" {
  description = "The name of the ALB"
  type        = string
}

variable "internal" {
  description = "Boolean determining if the ALB is internal or internet-facing"
  type        = bool
}

variable "vpc_id" {
  description = "The VPC ID where the ALB and Target Group will reside"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ALB"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of Security Group IDs for the ALB"
  type        = list(string)
}

variable "target_port" {
  description = "The port the Target Group will route traffic to"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "The path for the Target Group health check"
  type        = string
  default     = "/"
}