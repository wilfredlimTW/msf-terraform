variable "public_subnet_ids" {
  description = "List of public subnet IDs. The NAT Gateway will be placed in the first subnet of this list."
  type        = list(string)
}

variable "private_route_table_id" {
  description = "The ID of the private route table that needs outbound internet access."
  type        = string
}