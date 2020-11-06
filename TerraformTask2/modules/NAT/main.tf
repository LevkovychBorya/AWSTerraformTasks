resource "aws_eip" "eip" {
  vpc      = true

  tags = {
    Name = format("eip_%s", var.tag_owner)
    owner = var.tag_owner
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = var.public_subnet_id

  tags = {
    Name = format("nat_gw_%s", var.tag_owner)
    owner = var.tag_owner
  }
}

resource "aws_route_table" "nat_route" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = format("nat_route_%s", var.tag_owner)
    owner = var.tag_owner
  }
}

resource "aws_route_table_association" "private_subnets" {
  count = length(var.private_subnet_ids)

  subnet_id      = element(var.private_subnet_ids, count.index)
  route_table_id = aws_route_table.nat_route.id
}