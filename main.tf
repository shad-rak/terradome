data "aws_availability_zones" "available" {}

#Create VPC
resource "aws_vpc" "vpn_test" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vpn_test"
  }
}

#Create Internet Gateway and attach to VPC

resource "aws_internet_gateway" "vpn_public" {
  vpc_id = aws_vpc.vpn_test.id
  tags = {
        Name = "vpn_public"
    }
}

#Set the route for all outbound Internet traffic from public subnet
resource "aws_route_table" "vpn_public_rt" {
  vpc_id = aws_vpc.vpn_test.id

  route = {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpn_public.id
  }

  #Create the route table for the private subnet
  resource "aws_default_route_table" "vpn_private_rt" {
  default_route_table_id  = aws_vpc.vpn_test.default_route_table_id

  tags = {
    Name = "vpn_private"
  }
}

#Create the public subnet
resource "aws_subnet" "vpn_public_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.vpn_test.id
  cidr_block              = var.public_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags {
    Name = "vpn_public_" + [count.index + 1]
  }
}

#Create the private subnet
resource "aws_subnet" "vpn_private_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.vpn_test.id
  cidr_block              = var.public_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags {
    Name = "vpn_private_" + [count.index + 1]
  }
}

#Associate route tables
resource "aws_route_table_association" "vpn_public_assoc" {
  count          = aws_subnet.vpn_public_subnet.count
  subnet_id      = aws_subnet.vpn_public_subnet.*.id[count.index]
  route_table_id = aws_route_table.vpn_public_rt.id
}

resource "aws_route_table_association" "vpn_private_assoc" {
  count          = aws_subnet.vpn_private_subnet.count
  subnet_id      = aws_subnet.vpn_private_subnet.*.id[count.index]
  route_table_id = aws_route_table.vpn_private_rt.id
}

resource "aws_security_group" "vpn_public_sg" {
  name        = "vpn_public_sg"
  description = "Used for access to the public instances"
  vpc_id      = aws_vpc.vpn_test.id

  #SSH

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.accessip]
  }

  #HTTP

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.accessip]
  }
  
  #VPN access 
  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = [var.accessip]
  }

  #Egress all
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
