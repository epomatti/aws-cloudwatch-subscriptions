terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.17.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

locals {
  azs = ["${var.aws_region}a"]
}

module "vpc" {
  source         = "terraform-aws-modules/vpc/aws"
  name           = "prod-vpc"
  cidr           = "10.0.0.0/16"
  azs            = local.azs
  public_subnets = ["10.0.101.0/24"]
}

module "ec2" {
  source    = "./modules/ec2"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnets[0]
}

module "kinesis" {
  source = "./modules/kinesis/stream"
}

module "cloudwatch" {
  source                      = "./modules/cloudwatch"
  kinesis_stream_arn          = module.kinesis.kinesis_stream_arn
  subscription_filter_pattern = var.subscription_filter_pattern
}
