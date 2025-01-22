# Step 1: Set up the provider
provider "aws" {
  region = "us-east-1"
}

# Step 2: Create VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Step 3: Create Subnets
resource "aws_subnet" "subnet_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

# Step 4: Create Security Group
resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound and outbound traffic"
  
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Step 5: Create EC2 Instance
resource "aws_instance" "tasky" {
  ami             = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.tasky_key.key_name
  subnet_id       = aws_subnet.subnet_a.id
  security_groups = [aws_security_group.allow_all.name]

  tags = {
    Name = "Tasky-EC2-Instance"
  }
}

# Step 6: S3 Bucket for Backups
resource "aws_s3_bucket" "backup_bucket" {
  bucket = "tasky-backup-bucket"
  acl    = "private"
}

