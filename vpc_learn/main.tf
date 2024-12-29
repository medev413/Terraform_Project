# Creating VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    name = "tf_vpc_demo"
  }
}

#Creating Public Subnets in AZ's 1A & 1B
resource "aws_subnet" "public-1A" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.0.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true
}

resource "aws_subnet" "public-1B" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
}

#Creating Private Subnets in AZ's 1A & 1B
resource "aws_subnet" "Private_1A" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "Private_1B" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1b"
}

#Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    name = "aws_igw"
  }
}

#Creating Elastic for Nat
resource "aws_eip" "nat_eip" {
    tags = {
      name = "nat_eip"
    }
}

#Creating NAT Gateway
resource "aws_nat_gateway" "NAT_GW" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id = aws_subnet.public-1A.id
}

#Creating Public Route Table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id
}

#Creating public default Route
resource "aws_route" "public_default_route" {
    route_table_id = aws_route_table.public_route_table.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
}

#Public route table associations to public subnets
resource "aws_route_table_association" "public_sn1_association" {
  route_table_id = aws_route_table.public_route_table.id
  subnet_id = aws_subnet.public-1A.id
}

resource "aws_route_table_association" "public_Sn2_association" {
  route_table_id = aws_route_table.public_route_table.id
  subnet_id = aws_subnet.public-1B.id
}

#Creating Private Route Table
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id
}

#Creating private default Route
resource "aws_route" "private_default_route" {
  route_table_id = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.NAT_GW.id
}

#Private route table associations to private subnets
resource "aws_route_table_association" "private_Sn1_association" {
  route_table_id = aws_route_table.private_route_table.id
  subnet_id = aws_subnet.Private_1A.id
}

resource "aws_route_table_association" "private_Sn2_association" {
  route_table_id = aws_route_table.private_route_table.id
  subnet_id = aws_subnet.Private_1B.id
}

#Creating Security group with allowing SSH(22), HTTP(80) & all outbound
resource "aws_security_group" "vpc-default-sg" {
  vpc_id = aws_vpc.main.id
  tags = {
    name = "demo_vpc_default_sg"
  }

  ingress {
    description = "Allows HTTP Port"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH Port"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outboud Traffic"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Creating SG with allowing port 8082 (Python Server) & Outbound
resource "aws_security_group" "vpc-private-ec2-sg" {
  vpc_id = aws_vpc.main.id
  name = "demo_vpc_private_ec2_sg"

  ingress {
    from_port = 8082
    to_port = 8082
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "EC2-public" {
  ami = var.ami_id
  instance_type = var.ec2_instance_type
  subnet_id = aws_subnet.public-1A.id
  vpc_security_group_ids = [ aws_security_group.vpc-default-sg.id ]
  tags = {
    Name = "Baiston Host"
  }
}

resource "aws_instance" "EC2-Private-1A" {
  ami = var.ami_id
  instance_type = var.ec2_instance_type
  subnet_id = aws_subnet.Private_1A.id
  vpc_security_group_ids = [
    aws_security_group.vpc-default-sg.id,
    aws_security_group.vpc-private-ec2-sg.id
  ]
  tags = {
    Name = "EC2_pr_1A"
  }
  user_data = base64encode(file("userdata.sh"))
}

resource "aws_instance" "EC2-Private-1B" {
  ami = var.ami_id
  instance_type = var.ec2_instance_type
  subnet_id = aws_subnet.Private_1B.id
  vpc_security_group_ids = [
    aws_security_group.vpc-default-sg.id,
    aws_security_group.vpc-private-ec2-sg.id
  ]
  tags = {
    Name = "EC2_pr_1B"
  }
  user_data = base64encode(file("userdata.sh"))
}

resource "aws_lb" "load_balancer" {
  name = "demo-vpc-tf-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = [ aws_security_group.vpc-default-sg.id, aws_security_group.vpc-private-ec2-sg.id ]
  subnets = [ aws_subnet.public-1A.id, aws_subnet.public-1B.id ]
  tags = {
    Name = "demo-vpc-tf-alb"
  }
}

resource "aws_lb_target_group" "alb-tg" {
  name = "demo-vpc-alb-tg"
  protocol = "HTTP"
  port = "80"
  vpc_id = aws_vpc.main.id
  health_check {
    protocol = "HTTP"
    path = "/"
  }
}

resource "aws_lb_listener" "alb-listener" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port = "8082"
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.alb-tg.arn
  }
}

resource "aws_lb_target_group_attachment" "alb-tg-attach-1A" {
  target_group_arn = aws_lb_target_group.alb-tg.arn
  target_id = aws_instance.EC2-Private-1A.id
  port = "8082"
}

resource "aws_lb_target_group_attachment" "alb-tg-attach-1B" {
  target_group_arn = aws_lb_target_group.alb-tg.arn
  target_id = aws_instance.EC2-Private-1B.id
  port = "80"
}

