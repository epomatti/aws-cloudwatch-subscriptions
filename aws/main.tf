terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

locals {
  aws_account_id = data.aws_caller_identity.current.account_id
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

### EC2 IAM ###

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
  source                      = "terraform-aws-modules/ec2-instance/aws"
  name                        = "prod-instance"
  instance_type               = "t2.micro"
  user_data                   = file("${path.module}/cloud-init.sh")
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

resource "aws_cloudwatch_log_stream" "main" {
  name           = "trunk"
  log_group_name = aws_cloudwatch_log_group.main.name
}

resource "aws_cloudwatch_log_subscription_filter" "prod_kinesis_logfilter" {
  name            = "prod-kinesis"
  role_arn        = aws_iam_role.prod_cloudwatch_kinesis_role.arn
  log_group_name  = aws_cloudwatch_log_group.main.name
  filter_pattern  = var.subscription_filter_pattern
  destination_arn = aws_kinesis_stream.prod.arn
  distribution    = "Random"

  depends_on = [aws_iam_role_policy_attachment.prod_cwl_kinesis]
}

### Kinesis ###

resource "aws_iam_role" "prod_cloudwatch_kinesis_role" {
  name = "prod-cloudwatch-kinesis-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "logs.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "kinesis_cwl" {
  name = "prod-sub-kinesis-cwl"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kinesis:PutRecord",
        ]
        Effect   = "Allow"
        Resource = "${aws_kinesis_stream.prod.arn}"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "prod_cwl_kinesis" {
  role       = aws_iam_role.prod_cloudwatch_kinesis_role.name
  policy_arn = aws_iam_policy.kinesis_cwl.arn
}

resource "aws_kinesis_stream" "prod" {
  name             = "prod-cloudwatch-subscription"
  retention_period = 48

  shard_level_metrics = [
    "IncomingBytes",
    "IncomingRecords",
    "OutgoingBytes",
    "OutgoingRecords"
  ]

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }
}

### Firehose to Splunk ###

# resource "aws_kinesis_firehose_delivery_stream" "splunk" {
#   name        = "prod-splunk"
#   destination = "splunk"

#   kinesis_source_configuration {
#     kinesis_stream_arn = aws_kinesis_stream.prod.arn
#     role_arn           = aws_iam_role.firehose.arn
#   }

#   splunk_configuration {
#     hec_endpoint               = var.splunk_hec_endpoint
#     hec_token                  = var.splunk_hec_token
#     hec_acknowledgment_timeout = 600
#     hec_endpoint_type          = "Event"
#     # s3_backup_mode             = "FailedEventsOnly"

#     # s3_configuration {
#     #   role_arn           = aws_iam_role.firehose.arn
#     #   bucket_arn         = aws_s3_bucket.bucket.arn
#     #   buffering_size     = 10
#     #   buffering_interval = 400
#     #   compression_format = "GZIP"
#     # }
#   }
# }

# resource "aws_kinesis_stream_consumer" "firehose_splunk" {
#   name       = "prod-firehose-splunk"
#   stream_arn = aws_kinesis_stream.splunk.arn
# }

resource "aws_iam_role" "firehose" {
  name = "prod-firehose-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowFirehose"
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      }
    ]
  })
}


### OpenSearch Serverless ###

resource "aws_opensearchserverless_security_policy" "example" {
  name = "aos-prod-logs-secpol"
  type = "encryption"
  policy = jsonencode({
    "Rules" = [
      {
        "Resource" = [
          "collection/prod-logs"
        ],
        "ResourceType" = "collection"
      }
    ],
    "AWSOwnedKey" = true
  })
}

resource "aws_opensearchserverless_collection" "prod_logs" {
  name = "prod-logs"
  depends_on = [
    aws_opensearchserverless_security_policy.example,
    aws_opensearchserverless_access_policy.test
  ]
}

data "aws_partition" "current" {}

resource "aws_opensearchserverless_access_policy" "test" {
  name = "prod-access"
  type = "data"
  policy = jsonencode([
    {
      "Rules" : [
        {
          "ResourceType" : "collection",
          "Resource" : [
            "collection/prod-logs",
          ],
          "Permission" : [
            "aoss:*",
          ]
        }
      ],
      "Principal" : [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/Evandro"
      ]
    }
  ])
}

resource "aws_kinesis_firehose_delivery_stream" "opensearch_serverless" {
  name        = "prod-splunk"
  destination = "splunk"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.prod.arn
    role_arn           = aws_iam_role.firehose.arn
  }

  opensearch_configuration {
    
  }

  # opensearch_configuration {
  #   domain_arn = aws_opensearchserverless_collection.prod_logs.arn
  #   role_arn   = aws_iam_role.firehose.arn
  #   index_name = "test"

  #   s3_configuration {
  #     role_arn   = aws_iam_role.firehose.arn
  #     bucket_arn = aws_s3_bucket.bucket.arn
  #   }

  #   vpc_config {
  #     subnet_ids         = [aws_subnet.first.id, aws_subnet.second.id]
  #     security_group_ids = [aws_security_group.first.id]
  #     role_arn           = aws_iam_role.firehose.arn
  #   }
  # }
}
