variable "environment" {
  description = "The environment name"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the Internet VPC where the firewall will be deployed"
  type        = string
}

variable "firewall_subnet_ids" {
  description = "List of dedicated subnet IDs for the Network Firewall endpoints"
  type        = list(string)
}