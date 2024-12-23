resource "aws_instance" "EC2_instance" {
  ami = var.ami_value
  instance_type = var.instance_type_value
  tags = {
    name = "tf-var-demo"
  }
}