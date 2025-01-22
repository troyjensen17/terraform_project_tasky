provider "aws" {
  region = "us-east-1"
}

resource "aws_key_pair" "tasky_key" {
  key_name   = "tasky-key"
  public_key = tls_public_key.tasky_key.public_key_openssh
}

resource "tls_private_key" "tasky_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_vpc" "tasky_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "tasky-vpc"
  }
}

resource "aws_subnet" "tasky_subnet" {
  vpc_id     = aws_vpc.tasky_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "tasky-subnet"
  }
}

resource "aws_security_group" "tasky_sg" {
  description = "Allow SSH and MongoDB access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH"
  }

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow MongoDB access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "tasky-sg"
  }
}

resource "aws_instance" "tasky" {
  ami           = "ami-043a5a82b6cf98947" # Amazon Linux 2 AMI
  instance_type = "t2.micro"
  key_name      = aws_key_pair.tasky_key.key_name
  subnet_id     = aws_subnet.tasky_subnet.id
  security_groups = [aws_security_group.tasky_sg.name]

  tags = {
    Name = "tasky-instance"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              service docker start
              usermod -aG docker ec2-user
              docker run -d -p 80:80 --name tasky-tasky jeffthorne/tasky
              EOF
}

resource "aws_s3_bucket" "backup_bucket" {
  bucket = "database-backups-project"
  acl    = "private"

  tags = {
    Name = "backup-bucket"
  }
}

resource "aws_s3_bucket_object" "backup_object" {
  bucket = aws_s3_bucket.backup_bucket.bucket
  key    = "backup.tar.gz"
  source = "/path/to/backup.tar.gz" # Remove this if you're no longer using backup.tar.gz
  acl    = "private"
}

