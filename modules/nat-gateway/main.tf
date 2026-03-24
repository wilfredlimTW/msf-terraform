# 1. Elastic IP for the NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "primary-nat-eip"
    Tier = "Public"
  }
}

# 2. The NAT Gateway
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = var.public_subnet_ids[0]

  tags = {
    Name = "primary-nat-gateway"
  }

  # Ensure the EIP is fully created before attempting to attach it
  depends_on = [aws_eip.nat]
}

# 3. Private Route Entry
# This automatically gives anything attached to the private route table
# outbound access to the internet via the NAT Gateway.
resource "aws_route" "private_internet_access" {
  route_table_id         = var.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}