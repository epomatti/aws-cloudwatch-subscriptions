variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "cwagent_config_file_name" {
  type    = string
  default = "config-root-only-1s.json"
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
