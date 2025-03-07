################################################################################
# main.tf - Core module implementation
################################################################################

resource "aws_cloudwatch_metric_alarm" "this" {
  # Basic alarm configuration
  alarm_name        = var.alarm_name
  alarm_description = var.alarm_description
  actions_enabled   = var.actions_enabled

  # Action configuration
  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions

  # Alarm evaluation configuration
  comparison_operator = var.comparison_operator
  evaluation_periods  = var.evaluation_periods
  threshold           = var.threshold
  datapoints_to_alarm = var.datapoints_to_alarm
  treat_missing_data  = var.treat_missing_data

  # Conditional metric configuration based on mode
  dynamic "metric_query" {
    for_each = local.is_metric_math_mode ? local.metric_queries : []

    content {
      id          = metric_query.value.id
      expression  = metric_query.value.expression
      label       = metric_query.value.label
      return_data = metric_query.value.return_data

      dynamic "metric" {
        for_each = metric_query.value.has_metric ? [1] : []

        content {
          metric_name = metric_query.value.metric_name
          namespace   = metric_query.value.namespace
          period      = metric_query.value.period
          stat        = metric_query.value.stat
          unit        = metric_query.value.unit
          dimensions  = metric_query.value.dimensions
        }
      }
    }
  }

  # Single metric configuration (only used when not in metric math mode)
  metric_name = local.is_metric_math_mode ? null : var.metric_name
  namespace   = local.is_metric_math_mode ? null : var.namespace
  period      = local.is_metric_math_mode ? null : var.period
  statistic   = local.is_metric_math_mode ? null : var.statistic
  dimensions  = local.is_metric_math_mode ? null : var.dimensions

  tags = merge(
    var.tags,
    var.default_tags,
    {
      Name = var.alarm_name
    }
  )
}