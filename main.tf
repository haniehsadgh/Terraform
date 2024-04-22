# Haniehsadat Gholamhosseini

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-west-2"
}

# Create a VPC
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}


# Ec2 config
resource "aws_vpc" "main" {
  cidr_block     = var.base_cidr_block
  instance_tenancy       = "default"

  tags   = {
        Name = "main"
  }
}

variable "base_cidr_block" {
  description = "default cidr block for vpc"
  default     = "10.0.0.0/16"
}

# Creare a public subnet
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "main"
  }
}

# Create a private subnet
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = false

  tags = {
    Name = "private"
  }
}


resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-ipg"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-route"
  }
}

# Create a private routing table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-route"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

#resource "aws_route_table_association" "private" {
#  subnet_id      = aws_subnet.private.id
#  route_table_id = aws_route_table.private.id
#}

# security group for public instance!
resource "aws_security_group" "main" {
  name           = "main-sg"
  vpc_id         = aws_vpc.main.id
}

# security group for private instance!
resource "aws_security_group" "private" {
  name           = "main-private-sg"
  vpc_id         = aws_vpc.main.id
}

# security group egress or outbound rules for public ec2 instance!
resource "aws_vpc_security_group_egress_rule" "main" {
# make this open to everything from everywhere
#  type          = "egress"
security_group_id = aws_security_group.main.id
  from_port      = 0
  to_port        = 0
  ip_protocol    = "-1"
  cidr_ipv4      = "0.0.0.0/0"
}

# security group ingress or inbound rules for public ec2 instance !
resource "aws_vpc_security_group_ingress_rule" "ssh" {
# ssh and http in from everywhere
#  type          = "ingress"
security_group_id = aws_security_group.main.id
  from_port      = 22
  to_port        = 22
  ip_protocol    = "tcp"
  cidr_ipv4      = "0.0.0.0/0"
}

# security group ingress rules for public instance!
resource "aws_vpc_security_group_ingress_rule" "http" {
# ssh and http in from everywhere
#  type           = "ingress"
security_group_id = aws_security_group.main.id
  from_port      = 80
  to_port        = 80
  ip_protocol       = "tcp"
  cidr_ipv4    = "0.0.0.0/0"
}

# security group ingress rules for private instance !
resource "aws_vpc_security_group_ingress_rule" "ssh-private" {
# ssh and http in from everywhere
#  type          = "ingress"
security_group_id = aws_security_group.private.id
  from_port      = 22
  to_port        = 22
  ip_protocol    = "tcp"
  cidr_ipv4      = "${aws_vpc.main.cidr_block}"
}

# security group ingress rules for private instance!
resource "aws_vpc_security_group_ingress_rule" "http-private" {
# ssh and http in from everywhere
#  type           = "ingress"
security_group_id = aws_security_group.private.id
  from_port      = 80
  to_port        = 80
  ip_protocol    = "tcp"
  cidr_ipv4      = "${aws_vpc.main.cidr_block}"
}

# security group egress rules (outbound rule)for private instance !
resource "aws_vpc_security_group_egress_rule" "private" {
# make this open to everything from everywhere
#  type          = "egress"
security_group_id = aws_security_group.private.id
  from_port      = 0
  to_port        = 0
  ip_protocol    = "-1"
  cidr_ipv4      = "0.0.0.0/0"
}

# get the most recent ami for Ubuntu 22.04
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-lunar-23.04-amd64-server-*"]
  }
}

# key pair from local key COMPLETE ME!
resource "aws_key_pair" "local_key" {
  key_name   = "demo_key"
  public_key = file("~/demo_key.pem.pub")
}

# ec2 instance COMPLETE ME!
resource "aws_instance" "ubuntu" {
  instance_type = "t2.micro"
  ami           = data.aws_ami.ubuntu.id

  user_data     = <<-EOF
                #!/bin/bash
                apt-get update && apt-get install -y nginx
                EOF
  tags = {
    Name = "ubuntu-server"
  }

  key_name               = aws_key_pair.local_key.key_name
  vpc_security_group_ids = [aws_security_group.main.id]
  subnet_id              = aws_subnet.main.id

  root_block_device {
    volume_size = 10
  }
}

# ec2 instance in private subnet!
resource "aws_instance" "private" {
  instance_type = "t2.micro"
  ami           = data.aws_ami.ubuntu.id

  tags = {
    Name = "ubuntu-server"
  }

  key_name               = aws_key_pair.local_key.key_name
  vpc_security_group_ids = [aws_security_group.private.id]
  subnet_id              = aws_subnet.private.id

  root_block_device {
    volume_size = 10
  }
}

# output public ip address of the 2 instances
output "instance_public_ips" {
  value = aws_instance.ubuntu.public_ip
}

output "instance_private_ips" {
  value = aws_instance.private.private_ip
}
