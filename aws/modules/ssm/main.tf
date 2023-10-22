locals {
  config_file = file("${path.module}/${var.cwagent_config_file_name}")
}

resource "aws_ssm_parameter" "cloudwath_config_file" {
  name  = "AmazonCloudWatch-linux-terraform"
  type  = "String"
  value = local.config_file
}
