terraform {
  cloud {
    organization = "edwinkwesi"

    workspaces {
      name = "Linux-Deployment"
    }
  }
}


provider "aws" {
  profile = "default"
  region  = "eu-west-2"
}

resource "aws_vpc" "sky_vpc" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "SKY VPC"
  }
}

resource "aws_subnet" "sky_public_subnet" {
  vpc_id            = aws_vpc.sky_vpc.id
  cidr_block        = "172.16.1.0/24"
  availability_zone = "eu-west-2a"

  tags = {
    Name = "Sky Subnet"
  }
}

resource "aws_subnet" "sky_private_subnet" {
  vpc_id            = aws_vpc.sky_vpc.id
  cidr_block        = "172.16.2.0/24"
  #availability_zone = "eu-wast-2a"

  tags = {
    Name = "Sky Private Subnet"
  }
}

resource "aws_internet_gateway" "sky_ig" {
  vpc_id = aws_vpc.sky_vpc.id

  tags = {
    Name = "Sky Internet Gateway"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.sky_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sky_ig.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.sky_ig.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table_association" "public_1_rt_a" {
  subnet_id      = aws_subnet.sky_public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

#
resource "aws_security_group" "web_sg" {
  name   = "HTTP and SSH"
  vpc_id = aws_vpc.sky_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web_instance" {
  ami           = "ami-0e5f882be1900e43b"
  instance_type = "t2.nano"
  key_name      = "sky_key"

  subnet_id                   = aws_subnet.sky_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

user_data =<<EOF
		#! /bin/bash
        sudo apt-get update
		sudo apt-get install -y apache2
		sudo systemctl start apache2
		sudo systemctl enable apache2
		echo "<h1>Deployed via Terraform</h1>" | sudo tee /var/www/html/index.html
	EOF

    tags = {
        Name = "skyvm"
    }

  
}

resource "aws_key_pair" "skykeypair" {
  key_name = "sky_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDGZCF5bI7X7VsQOuJiwdt8vBSOAKhsxNh/2rKJwRtCPgfWNnnwh/y/g1HlfhSkHXXbomnvUdNRmSu9ckEFVQSLhP+pUtXwiVADbMIY4ZBuBBhmy2Jf8K/AFaGTXQscMSGsSDKEW7vUFidTRFsPtFhDe8wor6zR2agIXbbQhU4TLOkK4GiDBHvb2gODUSm5ceZ80nZHoEafKDbKvvw5Z9eAswwx0r7kyRR+o02dpbGvRF0zyMizYIEz9VppssJ5jc/I2TrkEU2gZ1owmJMAKh834rCWmSJUuqgy+N/56b7EXKfQDzF4Ob/c+tx5OsQKT8QjHf5/9lM9/4ikeLnRJLfPhn/NrIzdPOgEnk9dEaA/7YwJ91jhBb2WIFSBajQ9GCPyvsiQlL/YwOWaEt7jHZbcxwE+j/Vy1uGdZrh8jlZTrMh8fklCEjUTCF26D5gab5EYq5EC2PZO7Iud0n+waTIUWpSk8CVyRFSy7zsIhz+H0VZthDEroVG/Ot95IESmfX8= user@DESKTOP-F9CGK9L"
}