terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  backend "s3" {
    bucket  = "craft-europa-ecs-tf-state"
    key     = "tfstate"
    region  = "us-east-1"
    profile = "craft-ecs-terraform"
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Environment = "POC"
      Project     = "Craft ECS PoC"
    }
  }
}
