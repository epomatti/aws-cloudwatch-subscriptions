resource "aws_cloudwatch_metric_alarm" "disk" {
  alarm_name                = "terraform-linux-disk"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  metric_name               = "disk_used_percent"
  namespace                 = "CWAgent"
  period                    = 60
  statistic                 = "Average"
  threshold                 = 80
  alarm_description         = "Instance disk used percent"
  insufficient_data_actions = []

  dimensions = {
    InstanceId = var.instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "memory" {
  alarm_name                = "terraform-linux-memory"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  metric_name               = "mem_used_percent"
  namespace                 = "CWAgent"
  period                    = 60
  statistic                 = "Average"
  threshold                 = 80
  alarm_description         = "Instance memory used percent"
  insufficient_data_actions = []

  dimensions = {
    InstanceId = var.instance_id
  }
}

