# 1. The Transit Gateway
resource "aws_ec2_transit_gateway" "this" {
  description                     = "Central Hub TGW"
  auto_accept_shared_attachments  = "enable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  dns_support                     = "enable"

  tags = {
    Name = var.tgw_name
  }
}

# 2. Attach the Internet VPC (The Hub)
resource "aws_ec2_transit_gateway_vpc_attachment" "internet" {
  subnet_ids         = var.internet_tgw_subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id             = var.internet_vpc_id

  tags = {
    Name = "${var.tgw_name}-internet-attachment"
  }
}

# 3. Attach the Workload VPC (The Spoke)
resource "aws_ec2_transit_gateway_vpc_attachment" "workload" {
  subnet_ids         = var.workload_tgw_subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id             = var.workload_vpc_id

  tags = {
    Name = "${var.tgw_name}-workload-attachment"
  }
}

# ==========================================
# VPC ROUTING INJECTIONS
# ==========================================

# 4. Route Workload bound traffic from Internet VPC (Public) -> TGW
resource "aws_route" "internet_public_to_workload" {
  route_table_id         = var.internet_public_route_table_id
  destination_cidr_block = var.workload_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.this.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.internet]
}

# 5. Route Workload bound traffic from Internet VPC (Private) -> TGW
resource "aws_route" "internet_private_to_workload" {
  route_table_id         = var.internet_private_route_table_id
  destination_cidr_block = var.workload_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.this.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.internet]
}

# 6. Route all internet bound traffic from Workload VPC -> TGW
resource "aws_route" "workload_to_internet" {
  route_table_id         = var.workload_private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.this.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.workload]
}