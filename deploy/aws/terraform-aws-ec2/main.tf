provider "aws" {
  region = "us-west-1"  # Replace with your desired AWS region
}
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"  # Replace with your desired VPC CIDR block

  tags = {
    Name = "example-vpc"
  }
}

resource "aws_subnet" "example" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.0.0/24"  # Replace with your desired subnet CIDR block

  tags = {
    Name = "example-subnet"
  }
}

resource "aws_instance" "example" {
  ami           = "ami-07655b4bbf3eb3bd0"  # Ubuntu 20.04 LTS ARM64 AMI ID
  instance_type = "m5.xlarge"  # Replace with your desired instance type

  key_name = "personal"  # Replace with the name of your key pair

  subnet_id = aws_subnet.example.id
  vpc_security_group_ids = [aws_security_group.example.id]

  tags = {
    Name = "example-instance"
  }
}

resource "aws_security_group" "example" {
  name        = "example-security-group"
  description = "Allow SSH from local IP address"

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

data "http" "ip" {
  url = "http://ipinfo.io/ip"
}

output "public_ip" {
  value = aws_instance.example.public_ip
}
