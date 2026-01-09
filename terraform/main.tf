terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket = "12soat-terraform-state-k8s"
    key    = "infra-k8s/terraform.tfstate"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
