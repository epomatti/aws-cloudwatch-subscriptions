output "firehose_arn" {
  value = aws_kinesis_firehose_delivery_stream.s3.arn
}
