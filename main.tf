provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "tasky_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "tasky_subnet" {
  vpc_id                  = aws_vpc.tasky_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_security_group" "tasky_sg" {
  name        = "tasky-sg"
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
}

resource "aws_key_pair" "tasky_key" {
  key_name   = "tasky_key"
  public_key = ssh_key_pair.tasky_key.public_key
}

resource "tls_private_key" "tasky_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_instance" "tasky" {
  ami             = "ami-0c55b159cbfafe1f0"  # Replace with the correct AMI ID for Amazon Linux 2
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.tasky_subnet.id
  key_name        = aws_key_pair.tasky_key.key_name
  security_groups = [aws_security_group.tasky_sg.name]

  tags = {
    Name = "tasky-instance"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y git
              yum install -y mongodb
              systemctl start mongod
              systemctl enable mongod
              EOF
}

resource "aws_s3_bucket" "backup_bucket" {
  bucket = "tasky-backup-bucket-unique"
  acl    = "private"
}

resource "aws_s3_bucket_acl" "backup_bucket_acl" {
  bucket = aws_s3_bucket.backup_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_object" "backup_object" {
  bucket = aws_s3_bucket.backup_bucket.id
  key    = "backup-file"
  source = "path/to/your/local/file"
}

output "instance_public_ip" {
  value = aws_instance.tasky.public_ip
}

output "s3_bucket_name" {
  value = aws_s3_bucket.backup_bucket.bucket
}

output "ssh_private_key" {
  value     = tls_private_key.tasky_private_key.private_key_pem
  sensitive = true
}
