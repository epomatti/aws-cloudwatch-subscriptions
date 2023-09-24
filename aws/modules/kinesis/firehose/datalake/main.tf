resource "aws_kinesis_firehose_delivery_stream" "s3" {
  name        = "PUT-S3-LAKE"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose.arn
    bucket_arn = var.bucket_arn

    processing_configuration {
      enabled = "false"
    }
  }
}

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

resource "aws_iam_role_policy_attachment" "s3_fullaccess" {
  role       = aws_iam_role.firehose.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "kinesis" {
  role       = aws_iam_role.firehose.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonKinesisFullAccess"
}
