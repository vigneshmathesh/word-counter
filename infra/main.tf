terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# -------------------------
# VPC + Subnet + Networking
# -------------------------
resource "aws_vpc" "wc_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "word-counter-vpc"
  }
}

resource "aws_subnet" "wc_subnet" {
  vpc_id                  = aws_vpc.wc_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "word-counter-subnet"
  }
}

resource "aws_internet_gateway" "wc_igw" {
  vpc_id = aws_vpc.wc_vpc.id
  tags = {
    Name = "word-counter-igw"
  }
}

resource "aws_route_table" "wc_route" {
  vpc_id = aws_vpc.wc_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wc_igw.id
  }
  tags = {
    Name = "word-counter-rt"
  }
}

resource "aws_route_table_association" "wc_rta" {
  subnet_id      = aws_subnet.wc_subnet.id
  route_table_id = aws_route_table.wc_route.id
}

# -------------------------
# Security Group
# -------------------------
resource "aws_security_group" "wc_sg" {
  name        = "word-counter-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.wc_vpc.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -------------------------
# Ubuntu AMI
# -------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# -------------------------
# EC2 Instance
# -------------------------
resource "aws_instance" "wc_ec2" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.wc_subnet.id
  vpc_security_group_ids      = [aws_security_group.wc_sg.id]
  associate_public_ip_address = true
  key_name                    = "scale"

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y docker.io
              systemctl enable docker
              systemctl start docker
              docker pull ${var.docker_image}
              docker rm -f word-counter || true
              docker run -d --name word-counter -p 80:5000 ${var.docker_image}
              EOF

  tags = {
    Name = "word-counter"
  }
}

# -------------------------
# Outputs
# -------------------------
output "ec2_public_ip" {
  value = aws_instance.wc_ec2.public_ip
}
