terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

### VPC ### 

module "vpc" {
  source         = "terraform-aws-modules/vpc/aws"
  name           = "prod-vpc"
  cidr           = "10.0.0.0/16"
  azs            = ["us-east-2a"]
  public_subnets = ["10.0.101.0/24"]
}

module "sg" {
  source = "terraform-aws-modules/security-group/aws"

  name   = "prod-sg"
  vpc_id = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

### IAM ###

resource "aws_iam_role" "main" {
  name = "prod-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm-managed-instance-core" {
  role       = aws_iam_role.main.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatc-agent-server-policy" {
  role       = aws_iam_role.main.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

### EC2 ###

resource "aws_iam_instance_profile" "main" {
  name = "ec2-test-profile"
  role = aws_iam_role.main.id
}

module "ec2_instance" {
  source        = "terraform-aws-modules/ec2-instance/aws"
  name          = "prod-instance"
  instance_type = "t2.micro"
  # key_name               = "prod-user"
  # user_data                   = file("${path.module}/cloud-init.sh")
  ami                         = "ami-03f38e546e3dc59e1"
  monitoring                  = true
  associate_public_ip_address = true
  vpc_security_group_ids      = [module.sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  iam_instance_profile        = aws_iam_instance_profile.main.id
}

### Cloud Watch ###

resource "aws_cloudwatch_log_group" "main" {
  name = "prod-logs"
}

# resource "aws_cloudwatch_log_subscription_filter" "test_lambdafunction_logfilter" {
#   name            = "test_lambdafunction_logfilter"
#   role_arn        = aws_iam_role.iam_for_lambda.arn
#   log_group_name  = "/aws/lambda/example_lambda_name"
#   filter_pattern  = "logtype test"
#   destination_arn = aws_kinesis_stream.test_logstream.arn
#   distribution    = "Random"
# }
