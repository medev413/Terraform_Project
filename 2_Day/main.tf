provider "aws" {
  region = var.region
}

resource "aws_instance" "ec2" {
  ami = var.ami_value
  instance_type = var.aws_instance_type

  tags = {
    name = "Terraform-Variable"
  }
}