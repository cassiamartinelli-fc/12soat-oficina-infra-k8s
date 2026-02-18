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

  ingress {
    from_port   = 30080
    to_port     = 30080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Kong NodePort (K3s)"
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "K3s API Server (kubectl)"
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

# EC2 Instance
resource "aws_instance" "oficina" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = "oficina-key"
  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.oficina.id]

  user_data = templatefile("${path.module}/user-data.sh", {
    jwt_secret = var.jwt_secret
  })

  tags = {
    Name = "oficina-mecanica"
  }
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
