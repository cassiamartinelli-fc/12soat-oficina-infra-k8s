variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "jwt_secret" {
  description = "JWT Secret (usado pelo Kong para validar tokens)"
  type        = string
  sensitive   = true
}
