resource "aws_s3_bucket" "main" {
  bucket = "bucket-datalake-001199"

  force_destroy = true
}
