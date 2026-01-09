variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "app_image" {
  description = "Docker image da aplicação NestJS"
  type        = string
  default     = "ghcr.io/cassiamartinelli-fc/12soat-oficina-app:latest"
}

variable "neon_database_url" {
  description = "Connection string do Neon PostgreSQL"
  type        = string
  sensitive   = true
}

variable "newrelic_license_key" {
  description = "New Relic License Key"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "JWT Secret"
  type        = string
  sensitive   = true
}
