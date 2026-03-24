variable "environment" {
  description = "The environment name"
  type        = string
}

variable "subnet_ids" {
  description = "List of Data Subnet IDs in the Workload VPC"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of Security Group IDs for the Aurora cluster"
  type        = list(string)
}

variable "database_name" {
  description = "The name of the initial database to create"
  type        = string
  default     = "echodb"
}

variable "master_username" {
  description = "The master username for the database"
  type        = string
  default     = "dbadmin"
}