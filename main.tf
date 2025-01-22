provider "aws" {
  region = "us-east-1"
}

# Create VPC
resource "aws_vpc" "tasky_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "tasky-vpc"
  }
}

# Create Subnet
resource "aws_subnet" "tasky_subnet" {
  vpc_id                  = aws_vpc.tasky_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "tasky-subnet"
  }
}

# Create Security Group
resource "aws_security_group" "tasky_sg" {
  description = "Allow SSH and MongoDB access"
  vpc_id      = aws_vpc.tasky_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tasky-sg"
  }
}

# Create EC2 Key Pair
resource "aws_key_pair" "tasky_key" {
  key_name   = "tasky-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIgrJjGPjc8dGK/PXK5i+4Ypm21oALmqH/4KXTkAPGxNNgMCAPNqAEHH50oyg7WTT6kmvSGzQwMIcYofGiNXnQdCQ44rd29WRWrSjuUkmOQrlrDDW8ivqLEXGDBfoxi++/hwNknIdqyUXG/zLK6Mfq676M93NITgpaemF5QFrLCbHrIuCcRInTmUZpHCQZ7x6iu1EOTcWgWY9ekkylNBX8uCCRj2DlJ6CNuSxNByzs7auyam+iZYB1NzKjoe2HMJrioR/fA8oGiG2aNh9NQL4vdMig4TwncTMDdzl82YdxBnD7MVEfyrqzF3f2wazLkF2a9oWGfIBZQuc66rW0SRXH troyjensen@Troys-MacBook-Pro.local"
}

# Create EC2 Instance (Amazon Linux 2)
resource "aws_instance" "tasky" {
  ami           = "ami-043a5a82b6cf98947"  # Corrected Amazon Linux 2 AMI
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.tasky_subnet.id
  security_group_ids = [aws_security_group.tasky_sg.id]
  key_name      = aws_key_pair.tasky_key.key_name
  associate_public_ip_address = true

  tags = {
    Name = "Tasky-Instance"
  }
}

# Create S3 Bucket for database backups
resource "aws_s3_bucket" "backup_bucket" {
  bucket = "database-backups-project"
  force_destroy = true

  tags = {
    Name = "backup-bucket"
  }
}

# Create the TLS Private Key
resource "tls_private_key" "tasky_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

