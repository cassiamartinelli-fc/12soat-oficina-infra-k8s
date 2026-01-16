# Security Group - apenas portas necessárias
resource "aws_security_group" "oficina" {
  name        = "oficina-sg"
  description = "Security group para Kong Gateway"

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Kong Proxy"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH (opcional)"
  }

  ingress {
    from_port   = 8001
    to_port     = 8001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Kong Admin API (debug)"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "oficina-sg"
  }
}

# Elastic IP
resource "aws_eip" "oficina" {
  domain = "vpc"
  tags = {
    Name = "oficina-eip"
  }
}

# EC2 Instance
resource "aws_instance" "oficina" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = "oficina-key"

  vpc_security_group_ids = [aws_security_group.oficina.id]

  user_data = templatefile("${path.module}/user-data.sh", {
    app_image            = var.app_image
    neon_database_url    = var.neon_database_url
    newrelic_license_key = var.newrelic_license_key
    jwt_secret           = var.jwt_secret
  })

  tags = {
    Name = "oficina-mecanica"
  }
}

# Associar Elastic IP
resource "aws_eip_association" "oficina" {
  instance_id   = aws_instance.oficina.id
  allocation_id = aws_eip.oficina.id
}

# AMI Ubuntu mais recente
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}
