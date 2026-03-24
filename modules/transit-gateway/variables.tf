variable "tgw_name" {
  description = "Name tag for the Transit Gateway"
  type        = string
}

variable "internet_vpc_id" {
  description = "ID of the Internet VPC"
  type        = string
}

variable "internet_tgw_subnet_ids" {
  description = "Subnet IDs in the Internet VPC for the TGW attachment"
  type        = list(string)
}

variable "internet_public_route_table_id" {
  description = "Public Route Table ID in the Internet VPC to inject Workload routes"
  type        = string
}

variable "internet_private_route_table_id" {
  description = "Private Route Table ID in the Internet VPC to inject Workload routes"
  type        = string
}

variable "workload_vpc_id" {
  description = "ID of the Workload VPC"
  type        = string
}

variable "workload_tgw_subnet_ids" {
  description = "Subnet IDs in the Workload VPC for the TGW attachment"
  type        = list(string)
}

variable "workload_private_route_table_id" {
  description = "Private Route Table ID in the Workload VPC to inject Default route"
  type        = string
}

variable "workload_vpc_cidr" {
  description = "CIDR block of the Workload VPC to route traffic from the Internet VPC"
  type        = string
}