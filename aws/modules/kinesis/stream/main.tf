resource "aws_kinesis_stream" "main" {
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
