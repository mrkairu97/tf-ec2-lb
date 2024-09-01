terraform {
  required_version = ">= 0.13.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.73"
    }
  }

  backend "s3" {
    bucket = "backupreports-kairu97-poc"
    key    = "terraform/infra/lb_ec2.tfstate"
    region = "ap-southeast-1"
  }
}
