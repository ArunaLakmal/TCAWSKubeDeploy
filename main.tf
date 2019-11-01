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

resource "aws_subnet" "tc_public2_subnet" {
  vpc_id = "${aws_vpc.tc_vpc.id}"
  cidr_block = "${var.cidrs["public2"]}"
  map_public_ip_on_launch = true
  availability_zone = "${data.aws_availability_zones.available.names[1]}"

  tags = {
      Name = "tc_public_subnet2"
  }
}

resource "aws_subnet" "tc_private1_subnet" {
  vpc_id = "${aws_vpc.tc_vpc.id}"
  cidr_block = "${var.cidrs["private1"]}"
  map_public_ip_on_launch = false
  availability_zone = "${data.aws_availability_zones.available.names[0]}"

  tags = {
      Name = "tc_private_subnet1"
  }
}

resource "aws_subnet" "tc_private2_subnet" {
  vpc_id = "${aws_vpc.tc_vpc.id}"
  cidr_block = "${var.cidrs["private2"]}"
  map_public_ip_on_launch = false
  availability_zone = "${data.aws_availability_zones.available.names[1]}"

  tags = {
      Name = "tc_private_subnet2"
  }
}

resource "aws_route_table_association" "tc_public1_association" {
  subnet_id = "${aws_subnet.tc_public1_subnet.id}"
  route_table_id = "${aws_route_table.tc_public_rt.id}"
}

resource "aws_route_table_association" "tc_public2_association" {
  subnet_id = "${aws_subnet.tc_public2_subnet.id}"
  route_table_id = "${aws_route_table.tc_public_rt.id}"
}

resource "aws_route_table_association" "tc_private1_association" {
  subnet_id = "${aws_subnet.tc_private1_subnet.id}"
  route_table_id = "${aws_default_route_table.tc_private_rt.id}"
}

resource "aws_route_table_association" "tc_private2_association" {
  subnet_id = "${aws_subnet.tc_private2_subnet.id}"
  route_table_id = "${aws_default_route_table.tc_private_rt.id}"
}









