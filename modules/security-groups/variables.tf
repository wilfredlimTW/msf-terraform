variable "environment" {
  description = "The environment name"
  type        = string
}

variable "internet_vpc_id" {
  description = "ID of the Internet VPC"
  type        = string
}

variable "internet_vpc_cidr" {
  description = "CIDR block of the Internet VPC (for cross-TGW ingress rules)"
  type        = string
}

variable "workload_vpc_id" {
  description = "ID of the Workload VPC"
  type        = string
}

variable "workload_vpc_cidr" {
  description = "CIDR block of the Workload VPC (for cross-TGW egress rules)"
  type        = string
}