variable "aws_region" {}
variable "aws_profile" {}
variable "vpc_cidr" {}
variable "cidrs" {
  type = "map"
}
variable "tc_key_name" {}
variable "public_key_path" {}
variable "tc_kube_instance" {}
variable "tc_ami" {}
