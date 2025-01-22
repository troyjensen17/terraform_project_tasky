provider "aws" {
  region = "us-east-1"
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
  vpc_id                  = aws_vpc.tasky_vpc.id
  cidr_block             = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "tasky-subnet"
  }
}

resource "aws_security_group" "tasky_sg" {
  name_prefix = "tasky-sg"
  description = "Allow SSH and MongoDB access"

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

resource "aws_key_pair" "tasky_key" {
  key_name   = "tasky-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_instance" "tasky" {
  ami                    = "ami-xxxxxxxxxxxx"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.tasky_key.key_name
  security_groups        = [aws_security_group.tasky_sg.name]
  subnet_id              = aws_subnet.tasky_subnet.id
  associate_public_ip_address = true

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

resource "aws_s3_bucket_acl" "backup_acl" {
  bucket = aws_s3_bucket.backup_bucket.bucket
  acl    = "private"
}

resource "aws_s3_object" "backup_object" {
  bucket = aws_s3_bucket.backup_bucket.bucket
  key    = "backup.tar.gz"
  source = "/path/to/backup.tar.gz"
}

resource "tls_private_key" "tasky_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

