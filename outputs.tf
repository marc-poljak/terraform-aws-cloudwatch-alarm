################################################################################
# outputs.tf - Module outputs
################################################################################

output "id" {
  description = "The ID of the CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.this.id
}

output "arn" {
  description = "The ARN of the CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.this.arn
}

output "name" {
  description = "The name of the CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.this.alarm_name
}

output "description" {
  description = "The description of the CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.this.alarm_description
}

output "actions" {
  description = "Map of actions configured for the alarm"
  value = {
    enabled = aws_cloudwatch_metric_alarm.this.actions_enabled
    alarm   = aws_cloudwatch_metric_alarm.this.alarm_actions
    ok      = aws_cloudwatch_metric_alarm.this.ok_actions
  }
}

output "configuration" {
  description = "Map of alarm configuration settings"
  value = {
    comparison_operator = aws_cloudwatch_metric_alarm.this.comparison_operator
    evaluation_periods  = aws_cloudwatch_metric_alarm.this.evaluation_periods
    threshold           = aws_cloudwatch_metric_alarm.this.threshold
    datapoints_to_alarm = aws_cloudwatch_metric_alarm.this.datapoints_to_alarm
    treat_missing_data  = aws_cloudwatch_metric_alarm.this.treat_missing_data
  }
}

output "metric_details" {
  description = "Details about the metric or metrics being monitored"
  value = {
    type         = local.is_metric_math_mode ? "metric_math" : "single_metric"
    metric_name  = local.is_metric_math_mode ? null : aws_cloudwatch_metric_alarm.this.metric_name
    namespace    = local.is_metric_math_mode ? null : aws_cloudwatch_metric_alarm.this.namespace
    period       = local.is_metric_math_mode ? null : aws_cloudwatch_metric_alarm.this.period
    statistic    = local.is_metric_math_mode ? null : aws_cloudwatch_metric_alarm.this.statistic
    dimensions   = local.is_metric_math_mode ? null : aws_cloudwatch_metric_alarm.this.dimensions
    metric_query = local.is_metric_math_mode ? var.metric_query : null
  }
}