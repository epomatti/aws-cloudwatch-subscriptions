# resource "aws_kinesis_firehose_delivery_stream" "opensearch_serverless" {
#   name        = "prod-splunk"
#   destination = "splunk"

#   kinesis_source_configuration {
#     kinesis_stream_arn = aws_kinesis_stream.prod.arn
#     role_arn           = aws_iam_role.firehose.arn
#   }

#   opensearch_configuration {

#   }

#   # opensearch_configuration {
#   #   domain_arn = aws_opensearchserverless_collection.prod_logs.arn
#   #   role_arn   = aws_iam_role.firehose.arn
#   #   index_name = "test"

#   #   s3_configuration {
#   #     role_arn   = aws_iam_role.firehose.arn
#   #     bucket_arn = aws_s3_bucket.bucket.arn
#   #   }

#   #   vpc_config {
#   #     subnet_ids         = [aws_subnet.first.id, aws_subnet.second.id]
#   #     security_group_ids = [aws_security_group.first.id]
#   #     role_arn           = aws_iam_role.firehose.arn
#   #   }
#   # }
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
