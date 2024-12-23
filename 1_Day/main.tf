#Define Providers
provider "aws" {
    region = "us-east-1"
}

#Define Resource EC2 Instance
resource "aws_instance" "ec2_instance" {
    ami_id = "ami-0e2c8caa4b6378d8c"
    instance_type = t2.micro
}

#Define Name for EC2 Instance using tags
tags {
    Name = "terraform_demo"
}
