variable "region" {
  description = "Defining the region as variable"
  type = string
  default = "us-east-1"
}

variable "ami_value" {
  description = "Defining the ami id for EC2"
  type = string
  default = "ami-***"
}

variable "aws_instance_type" {
  description = "Defining the EC2 instance type"
  type = string
  default = "t2.micro"
}