resource "aws_cloudwatch_log_group" "main" {
  name = "prod-logs"
}

resource "aws_cloudwatch_log_stream" "main" {
  name           = "trunk"
  log_group_name = aws_cloudwatch_log_group.main.name
}

resource "aws_cloudwatch_log_subscription_filter" "prod_kinesis_logfilter" {
  name            = "prod-kinesis"
  role_arn        = aws_iam_role.main.arn
  log_group_name  = aws_cloudwatch_log_group.main.name
  filter_pattern  = var.subscription_filter_pattern
  destination_arn = var.kinesis_stream_arn
  distribution    = "Random"

  depends_on = [
    aws_iam_role_policy_attachment.kinesis
  ]
}

resource "aws_cloudwatch_log_subscription_filter" "firehose_datalake" {
  name            = "firehose-lake-s3"
  role_arn        = aws_iam_role.main.arn
  log_group_name  = aws_cloudwatch_log_group.main.name
  filter_pattern  = var.subscription_filter_pattern
  destination_arn = var.firehose_datalake_arn

  depends_on = [
    aws_iam_role_policy_attachment.kinesis
  ]
}

resource "aws_iam_role" "main" {
  name = "CustomLogReplication"

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

resource "aws_iam_policy" "kinesis" {
  name = "CustomCloudWatchPermissions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "KinesisStream"
        Action = [
          "kinesis:PutRecord"
        ]
        Effect   = "Allow"
        Resource = "${var.kinesis_stream_arn}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "kinesis" {
  role       = aws_iam_role.main.name
  policy_arn = aws_iam_policy.kinesis.arn
}
