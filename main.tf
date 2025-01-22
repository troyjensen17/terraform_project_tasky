provider "aws" {
  region = "us-east-1"
}

resource "tls_private_key" "tasky_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "tasky_key" {
  key_name   = "tasky-key"
  public_key = tls_private_key.tasky_key.public_key_openssh
}

resource "aws_vpc" "tasky_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "tasky_subnet" {
  vpc_id                  = aws_vpc.tasky_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "tasky-subnet"
  }
}

resource "aws_security_group" "tasky_sg" {
  name        = "tasky-sg"
  description = "Security group for tasky"
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

resource "aws_s3_bucket" "backup_bucket" {
  bucket = "database-backups-project"
  force_destroy = true
  tags = {
    Name = "backup-bucket"
  }
}

resource "aws_instance" "tasky" {
  ami                         = "ami-043a5a82b6cf98947"
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.tasky_key.key_name
  subnet_id                   = aws_subnet.tasky_subnet.id
  vpc_security_group_ids      = [aws_security_group.tasky_sg.id]  # Reference the security group by ID

  tags = {
    Name = "tasky-instance"
  }

  user_data = "e501a67afc0bfee985464517436fa65ec0e1fca4"
}

