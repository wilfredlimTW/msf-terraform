variable "environment" {
  description = "The environment name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the Workload VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of Web Subnet IDs in the Workload VPC"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of Security Group IDs for the NLB"
  type        = list(string)
}