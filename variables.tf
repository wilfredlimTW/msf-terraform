variable "aws_region" {
  description = "The AWS region to deploy infrastructure into"
  type        = string
  default     = "ap-southeast-1"
}

variable "environment" {
  description = "The environment name (e.g., dev, prod) corresponding to the workspace"
  type        = string
}

variable "vpc_cidr_internet" {
  description = "CIDR block for the Internet VPC"
  type        = string
}

variable "vpc_cidr_workload" {
  description = "CIDR block for the Workload VPC"
  type        = string
}