terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.22.0"
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

module "ssm" {
  source                   = "./modules/ssm"
  cwagent_config_file_name = var.cwagent_config_file_name
}

module "ec2" {
  source        = "./modules/ec2"
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.public_subnets[0]
  instance_type = var.ec2_instance_type

  depends_on = [module.ssm]
}

module "alarms" {
  source      = "./modules/alarms"
  instance_id = module.ec2.instance_id
}

module "s3_lake" {
  source = "./modules/s3"
}

module "firehose_datalake" {
  source     = "./modules/kinesis/firehose/datalake"
  bucket_arn = module.s3_lake.bucket_arn
}

module "kinesis_stream" {
  source = "./modules/kinesis/stream"
}

module "cloudwatch" {
  source                      = "./modules/cloudwatch"
  kinesis_stream_arn          = module.kinesis_stream.kinesis_stream_arn
  subscription_filter_pattern = var.subscription_filter_pattern
  firehose_datalake_arn       = module.firehose_datalake.firehose_arn
}
