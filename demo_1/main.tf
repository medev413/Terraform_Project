provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "demo-alb"
  }
}

resource "aws_subnet" "public-1a" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public-1b" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private-1a" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "private-1b" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# resource "aws_eip" "NAT_eip" {
#   tags = {
#     Name = "demo-vpc-eip"
#   }
# }

# resource "aws_nat_gateway" "nat_gw" {
#   allocation_id = aws_eip.NAT_eip.id
#   subnet_id = aws_subnet.public-1a.id
# }

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "public_default_route" {
  route_table_id = aws_route_table.public_route_table.id
  gateway_id = aws_internet_gateway.igw.id
  destination_cidr_block = "0.0.0.0/0" 
}

resource "aws_route_table_association" "public-1a-association" {
  route_table_id = aws_route_table.public_route_table.id
  subnet_id = aws_subnet.public-1a.id
}

resource "aws_route_table_association" "public-1b-association" {
  route_table_id = aws_route_table.public_route_table.id
  subnet_id = aws_subnet.public-1b.id
}

resource "aws_security_group" "webserver_sg" {
  name = "webserver_sg"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "Baiston" {
  ami = "ami-0e2c8caa4b6378d8c"
  instance_type = "t2.micro"
  security_groups = [ aws_security_group.webserver_sg.id ]
  subnet_id = aws_subnet.public-1a.id
}

resource "aws_instance" "ec2-private-1a" {
  ami = "ami-0e2c8caa4b6378d8c"
  instance_type = "t2.micro"
  security_groups = [ aws_security_group.webserver_sg.id ]
  subnet_id = aws_subnet.private-1a.id
  tags = {
    Name = "private-1a"
  }
  user_data = base64encode(file("userdata.sh"))
}

resource "aws_instance" "ec2-private-1b" {
  ami = "ami-0e2c8caa4b6378d8c"
  instance_type = "t2.micro"
  security_groups = [ aws_security_group.webserver_sg.id ]
  subnet_id = aws_subnet.private-1b.id
  tags = {
    Name = "private-1b"
  }
  user_data = base64encode(file("userdata.sh"))
}

resource "aws_lb" "alb" {
  name = "demo-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = [ aws_security_group.webserver_sg.id ]
  subnets = [ aws_subnet.public-1a.id, aws_subnet.public-1b.id ]
  tags = {
    Name = "demo-alb"
  }
}

resource "aws_lb_target_group" "alb_tg" {
  port = "80"
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id
  health_check {
    path = "/"
    protocol = "HTTP"
  }
  tags = {
    Name = "alb_tg"
  }
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port = "80"
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "alb_tg_attach1" {
  target_group_arn = aws_lb_target_group.alb_tg.arn
  target_id = aws_instance.ec2-private-1a.id
  port = 80
}

resource "aws_lb_target_group_attachment" "alb_tg_attach2" {
  target_group_arn = aws_lb_target_group.alb_tg.arn
  target_id = aws_instance.ec2-private-1b.id
  port = 80
}

output "lb_dns_resolver" {
  value = aws_lb.alb.dns_name
}