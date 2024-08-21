# VPC
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge({
    Name = "main-vpc"
  }, var.tags)
}

# Public Subnets
resource "aws_subnet" "public_subnet" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnets[count.index]
  map_public_ip_on_launch = true
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)

  tags = merge({
    Name = "public-subnet-${count.index + 1}"
  }, var.tags)
}

# Private Subnets
resource "aws_subnet" "private_subnet" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = merge({
    Name = "private-subnet-${count.index + 1}"
  }, var.tags)
}

# Internet Gateway
resource "aws_internet_gateway" "main_internet_gateway" {
  vpc_id = aws_vpc.main_vpc.id

  tags = merge({
    Name = "main-internet-gateway"
  }, var.tags)
}

# Route Table for Public Subnets
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_internet_gateway.id
  }

  tags = merge({
    Name = "public-route-table"
  }, var.tags)
}

# Route Table Association for Public Subnets
resource "aws_route_table_association" "public_route_association" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

# NAT Gateway (optional)
resource "aws_eip" "main_eip" {
  count = var.enable_nat_gateway ? 1 : 0
}

resource "aws_nat_gateway" "main_nat_gateway" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = element(aws_eip.main_eip.*.id, count.index)
  subnet_id     = element(aws_subnet.public_subnet.*.id, 0)

  tags = merge({
    Name = "main-nat-gateway"
  }, var.tags)
}

# Route Table for Private Subnets
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.enable_nat_gateway ? aws_nat_gateway.main_nat_gateway[0].id : null
  }

  tags = merge({
    Name = "private-route-table"
  }, var.tags)
}

# Route Table Association for Private Subnets
resource "aws_route_table_association" "private_route_association" {
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}

# Availability Zones
data "aws_availability_zones" "available" {}