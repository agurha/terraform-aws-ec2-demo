provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = "${data.aws_vpc.default.id}"
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name = "name"

    values = [
      "amzn-ami-hvm-*-x86_64-gp2",
    ]
  }

  filter {
    name = "owner-alias"

    values = [
      "amazon",
    ]
  }
}

module "security_group" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "ec2-us-east1"
  description = "Security group for example usage with EC2 instance"
  vpc_id      = "${data.aws_vpc.default.id}"

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "all-icmp"]
  egress_rules        = ["all-all"]
}

module "ec2" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name  = "my-cluster"
  count = 5
  
  ami                    = "${data.aws_ami.amazon_linux.id}"
  instance_type          = "t2.micro"
  subnet_id                    = "${element(data.aws_subnet_ids.all.ids, 0)}"
  vpc_security_group_ids        = ["${module.security_group.this_security_group_id}"]
  associate_public_ip_address   = true
  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

