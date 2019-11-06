aws_profile = "superhero"
aws_region  = "us-east-1"
vpc_cidr    = "10.0.0.0/16"
cidrs = {
  public1  = "10.0.1.0/24"
  public2  = "10.0.2.0/24"
  private1 = "10.0.3.0/24"
  private2 = "10.0.4.0/24"
}
tc_key_name      = "ironman"
public_key_path  = "/root/.ssh/ironman.pub"
tc_kube_instance = "t2.medium"
tc_ami           = "ami-00dc79254d0461090"
worker_nodes_count ="3"