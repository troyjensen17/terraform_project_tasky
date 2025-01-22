provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "tasky_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "tasky-vpc"
  }
}

resource "aws_subnet" "tasky_subnet" {
  vpc_id                  = aws_vpc.tasky_vpc.id
  cidr_block             = "10.0.1.0/24"
  availability_zone      = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "tasky-subnet"
  }
}

resource "aws_security_group" "tasky_sg" {
  description = "Allow SSH and MongoDB access"

  ingress = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 27017
      to_port     = 27017
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  egress = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  tags = {
    Name = "tasky-sg"
  }
}

resource "aws_key_pair" "tasky_key" {
  key_name   = "tasky-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIgrJjGPjc8dGK/PXK5i+4Ypm21oALmqH/4KXTkAPGxNNgMCAPNqAEHH50oyg7WTT6kmvSGzQwMIcYofGiNXnQdCQ44rd29WRWrSjuUkmOQrlrDDW8ivqLEXGDBfoxi++/hwNknIdqyUXG/zLK6Mfq676M93NITgpaemF5QFrLCbHrIuCcRInTmUZpHCQZ7x6iu1EOTcWgWY9ekkylNBX8uCCRj2DlJ6CNuSxNByzs7auyam+iZYB1NzKjoe2HMJrioR/fA8oGiG2aNh9NQL4vdMig4TwncTMDdzl82YdxBnD7MVEfyrqzF3f2wazLkF2a9oWGfIBZQuc66rW0SRXH troyjensen@Troys-MacBook-Pro.local"
}

resource "aws_instance" "tasky" {
  ami           = "ami-043a5a82b6cf98947"  # Amazon Linux 2 AMI ID
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.tasky_subnet.id
  key_name      = aws_key_pair.tasky_key.key_name
  vpc_security_group_ids = [aws_security_group.tasky_sg.id]  # Corrected argument

  tags = {
    Name = "Tasky-Instance"
  }
}

resource "aws_s3_bucket" "backup_bucket" {
  bucket = "database-backups-project"
  force_destroy = true

  tags = {
    Name = "backup-bucket"
  }
}

resource "tls_private_key" "tasky_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

