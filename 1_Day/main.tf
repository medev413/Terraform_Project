provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "ec2_instance" {
    ami = "ami-0e2c8caa4b6378d8c"
    instance_type = t2.micro
    tags = {
        Name = "terraform_demo"
    }
}




