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