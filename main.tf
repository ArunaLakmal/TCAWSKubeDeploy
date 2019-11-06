provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}
#---- VPC ----
resource "aws_vpc" "tc_vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true

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
  vpc_id                  = "${aws_vpc.tc_vpc.id}"
  cidr_block              = "${var.cidrs["public1"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags = {
    Name = "tc_public_subnet1"
  }
}

resource "aws_subnet" "tc_public2_subnet" {
  vpc_id                  = "${aws_vpc.tc_vpc.id}"
  cidr_block              = "${var.cidrs["public2"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"

  tags = {
    Name = "tc_public_subnet2"
  }
}

resource "aws_subnet" "tc_private1_subnet" {
  vpc_id                  = "${aws_vpc.tc_vpc.id}"
  cidr_block              = "${var.cidrs["private1"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags = {
    Name = "tc_private_subnet1"
  }
}

resource "aws_subnet" "tc_private2_subnet" {
  vpc_id                  = "${aws_vpc.tc_vpc.id}"
  cidr_block              = "${var.cidrs["private2"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"

  tags = {
    Name = "tc_private_subnet2"
  }
}

resource "aws_route_table_association" "tc_public1_association" {
  subnet_id      = "${aws_subnet.tc_public1_subnet.id}"
  route_table_id = "${aws_route_table.tc_public_rt.id}"
}

resource "aws_route_table_association" "tc_public2_association" {
  subnet_id      = "${aws_subnet.tc_public2_subnet.id}"
  route_table_id = "${aws_route_table.tc_public_rt.id}"
}

resource "aws_route_table_association" "tc_private1_association" {
  subnet_id      = "${aws_subnet.tc_private1_subnet.id}"
  route_table_id = "${aws_default_route_table.tc_private_rt.id}"
}

resource "aws_route_table_association" "tc_private2_association" {
  subnet_id      = "${aws_subnet.tc_private2_subnet.id}"
  route_table_id = "${aws_default_route_table.tc_private_rt.id}"
}

#---- Security Group COnfiguration ----

resource "aws_security_group" "tc_kubeadm_sg" {
  name        = "tc_kubeadm_sg"
  description = "Security Group for the Kube Admin"
  vpc_id      = "${aws_vpc.tc_vpc.id}"

  #---- SSH ----

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #---- HTTP Allow ----
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#---- Public Security Group ----

resource "aws_security_group" "tc_public_sg" {
  name        = "tc_public_sg"
  description = "Security Group for the Public instances"
  vpc_id      = "${aws_vpc.tc_vpc.id}"

  #---- HTTP Allow ----
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "tc_private_sg" {
  name        = "tc_private_sg"
  description = "Security Group for Private instances"
  vpc_id      = "${aws_vpc.tc_vpc.id}"

  #---- Access From VPC ----
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#---- Key Pair ----

resource "aws_key_pair" "tc_key" {
  key_name   = "${var.tc_key_name}"
  public_key = "${file(var.public_key_path)}"
}

#---- Kube Master ----

resource "aws_instance" "tc_kube_master" {
  instance_type = "${var.tc_kube_instance}"
  ami           = "${var.tc_ami}"

  tags = {
    Name = "tc_kube_master"
  }

  key_name               = "${aws_key_pair.tc_key.id}"
  vpc_security_group_ids = ["${aws_security_group.tc_kubeadm_sg.id}"]
  subnet_id              = "${aws_subnet.tc_public1_subnet.id}"
}

#---- Kube Workers ----

resource "aws_instance" "tc_kube_worker" {
  count         = "${var.worker_nodes_count}"
  instance_type = "${var.tc_kube_instance}"
  ami           = "${var.tc_ami}"

  tags = {
    Name = "tc_kube_worker ${count.index + 1}"
  }

  key_name               = "${aws_key_pair.tc_key.id}"
  vpc_security_group_ids = ["${aws_security_group.tc_private_sg.id}"]
  subnet_id              = "${aws_subnet.tc_public2_subnet.id}"
}

#---- Provision Ansible Inventory ----
resource "null_resource" "tc_instances" {
  provisioner "local-exec" {
    command = <<EOD
    cat <<EOF > kube_hosts
[kubemaster]
master ansible_host="${aws_instance.tc_kube_master.public_ip}" ansible_user=ec2-user
[kubeworkers]
worker1 ansible_host="${aws_instance.tc_kube_worker.0.public_ip}" ansible_user=ec2-user
worker2 ansible_host="${aws_instance.tc_kube_worker.1.public_ip}" ansible_user=ec2-user
worker3 ansible_host="${aws_instance.tc_kube_worker.2.public_ip}" ansible_user=ec2-user
EOF
EOD
interpreter = ["/bin/bash" , "-c"]
  }
}
