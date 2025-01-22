provider "aws" {
  region = "us-east-1"  # Use your desired AWS region
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
  name        = "tasky_sg"
  description = "Allow inbound SSH and HTTP"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
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
  key_name   = "tasky-key"
  public_key = file("~/.ssh/id_rsa.pub")  # Replace with the path to your public SSH key
}

resource "aws_instance" "tasky" {
  ami                    = "ami-0c55b159cbfafe1f0"  # Replace with your region-specific Ubuntu AMI
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.tasky_key.key_name
  subnet_id             = aws_subnet.tasky_subnet.id
  security_group_ids    = [aws_security_group.tasky_sg.id]

  # User data to pull the repository and start the website
  user_data = <<-EOF
              #!/bin/bash
              # Update and install necessary dependencies
              apt-get update -y
              apt-get install -y git nodejs npm

              # Clone the GitHub repository
              cd /home/ubuntu
              git clone https://github.com/jeffthorne/tasky.git
              cd tasky

              # Install Node.js dependencies
              npm install

              # Start the application
              nohup npm start &

              EOF

  tags = {
    Name = "Tasky Website"
  }
}

resource "aws_s3_bucket" "backup_bucket" {
  bucket = "database-backups-project"
  acl    = "private"
}

output "instance_public_ip" {
  value = aws_instance.tasky.public_ip
}

