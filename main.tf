provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
}
#---- VPC ----
resource "aws_vpc" "tc_vpc" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
      Name = "TC_VPC"
  }
}

#---- IGW ----
resource "aws_internet_gateway" "tc_igw" {
  vpc_id = "${aws_vpc.tc_vpc.id}"

  tags = {
      Name = "TC_IGW"
  }
}

#---- RT ----
resource "aws_route_table" "tc_public_rt" {
  vpc_id = "${aws_vpc.tc_vpc.id}"

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_internet_gateway.tc_igw.id}"
  }

  tags = {
      Name = "tc_public_rt"
  }
}

resource "aws_default_route_table" "tc_private_rt" {
  default_route_table_id = "${aws_vpc.tc_vpc.default_route_table_id}"

  tags = {
      Name = "tc_private_rt"
  }
}

#---- Subnets ----

data "aws_availability_zones" "available" {
  state = "available"
}
resource "aws_subnet" "tc_public1_subnet" {
  vpc_id = "${aws_vpc.tc_vpc.id}"
  cidr_block = "${var.cidrs["public1"]}"
  map_public_ip_on_launch = true
  availability_zone = "${data.aws_availability_zones.available.names[0]}"

  tags = {
      Name = "tc_public_subnet1"
  }
}


