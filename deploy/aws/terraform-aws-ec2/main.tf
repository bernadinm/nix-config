provider "aws" {
  region = "us-west-1"  # Replace with your desired AWS region
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"  # Replace with your desired VPC CIDR block

  tags = {
    Name = "example-vpc"
  }
}

resource "aws_route_table" "example" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example.id
  }

  tags = {
    Name = "example-route-table"
  }
}

resource "aws_route_table_association" "example" {
  subnet_id      = aws_subnet.example.id
  route_table_id = aws_route_table.example.id
}

resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "example-internet-gateway"
  }
}

resource "aws_subnet" "example" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.0.0/24"  # Replace with your desired subnet CIDR block

  tags = {
    Name = "example-subnet"
  }
}

resource "aws_key_pair" "personal" {
  key_name   = "personal-lumina"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL2zedCg5IeMEHH22A1zZqUyvIigOmPsWDbetomvTZvJ miguel@Lumina"
}

resource "aws_security_group" "example" {
  name        = "example-security-group"
  description = "Allow SSH from local IP address"

  vpc_id = aws_vpc.example.id  # Explicitly associate the security group with the VPC

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.http.ip.body}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "example" {
  ami           = "ami-07655b4bbf3eb3bd0"  # Ubuntu 20.04 LTS ARM64 AMI ID
  instance_type = "m6g.4xlarge"  # Replace with your desired instance type

  key_name = aws_key_pair.personal.key_name  # Replace with the name of your key pair

  subnet_id               = aws_subnet.example.id
  vpc_security_group_ids  = [aws_security_group.example.id]

  associate_public_ip_address = true  # Enable public IP address

  root_block_device {
    volume_size = 200
  }

  tags = {
    Name = "example-instance"
  }
}

data "http" "ip" {
  url = "http://ipinfo.io/ip"
}

output "public_ip" {
  value = aws_instance.example.public_ip
}
