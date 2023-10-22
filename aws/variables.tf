variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "ec2_instance_type" {
  type    = string
  default = "t4g.nano"
}

variable "subscription_filter_pattern" {
  type    = string
  default = ""
}

# variable "splunk_hec_endpoint" {
#   type = string
# }

# variable "splunk_hec_token" {
#   type      = string
#   sensitive = true
# }
