data "aws_availability_zones" "available" {}
#Create VPC
resource "aws_vpc" "vpn_test" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vpn_test"
  }
}

#Create Internet Gateway and attach to VPC

resource "aws_internet_gateway" "vpn_public" {
  vpc_id = "aws_vpc.vpn_test.id"
  tags = {
        Name = "vpn_gateway"
    }
}

