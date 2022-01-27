provider "aws" {
  profile = "terraform"
  shared_credentials_file = "/home/rkhozyainov/.aws/credentials"
  region  = "us-west-1"
}

data "aws_ami" "last-ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
    }

  owners = ["099720109477"] # Canonical
}

data "aws_caller_identity" "test_call_id" {}
data "aws_region" "test_reg" {}


resource "aws_instance" "test" {
    ami           = data.aws_ami.last-ubuntu.id
    instance_type = "t2.micro"
    #cpu_core_count = "2"
    tags = {
    Name = "test-ubuntu"
  }
}
#data "aws_vpc" "selected" {
#  tags = {
#    Name = "tf-example"
#  }
#}

#data "aws_subnet_ids" "selected" {
#  vpc_id = data.aws_vpc.selected.id
#  tags = {
#    Tier = "private"
#  }
#}

#resource "aws_vpc" "test_vpc" {
#        tags = {
#       Name = "tf-example"
#  }
#}
#resource "aws_subnet" "my_tesubnet" {
#        vpc_id = aws_vpc.test_vpc.id
#        tags = {
#        Name = "tf-example"
#  }
#}
