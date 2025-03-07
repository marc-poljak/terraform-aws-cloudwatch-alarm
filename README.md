# CloudWatch Alarm Module

A comprehensive Terraform module for creating and managing AWS CloudWatch alarms with support for both standard single metrics and advanced metric math expressions.

## ⚠️ Disclaimer
**USE AT YOUR OWN RISK**. This tool is provided "as is", without warranty of any kind, express or implied.
Neither the authors nor contributors shall be liable for any damages or consequences arising from the use of this tool.
Always:

* 🧪 Test in a non-production environment first
* ✓ Verify results manually before taking action
* 💾 Maintain proper backups
* 🔒 Follow your organization's security policies

## Features

* ⏰ Create standard CloudWatch alarms with single metrics
* 🧮 Create advanced alarms using CloudWatch metric math expressions
* ✅ Built-in validation to ensure valid configuration
* 📊 Support for percentage-based monitoring (e.g., storage utilization percentage)
* 🔔 Flexible alarm actions, evaluation periods, and thresholds
* 🏷️ Consistent tagging across your alarms
* 📤 Comprehensive output structure for integration with other modules

## Usage

### Basic Single-Metric Alarm

For simple metric monitoring, such as CPU utilization:

```terraform
module "cpu_utilization_alarm" {
  source = "path/to/cloudwatch_alarm"

  alarm_name        = "high-cpu-utilization"
  alarm_description = "CPU utilization exceeds 80% for 15 minutes"

  metric_name = "CPUUtilization"
  namespace   = "AWS/EC2"
  period      = 300
  statistic   = "Average"
  
  dimensions = {
    InstanceId = "i-1234567890abcdef0"
  }

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  threshold           = 80
  treat_missing_data  = "notBreaching"
  
  alarm_actions = [aws_sns_topic.alerts.arn]
  tags = {
    Environment = "Production"
    Service     = "Web"
  }
}
```

### Advanced Metric Math Alarm

For complex monitoring scenarios, such as calculating percentages or rates:

```terraform
module "lambda_error_rate_alarm" {
  source = "path/to/cloudwatch_alarm"

  alarm_name        = "lambda-high-error-rate"
  alarm_description = "Lambda function error rate exceeds 5%"

  # Enable metric math mode
  use_metric_query = true
  
  # Define metric queries
  metric_query = [
    {
      id          = "error_rate"
      expression  = "errors * 100 / invocations"
      label       = "Error Rate (%)"
      return_data = true
    },
    {
      id          = "errors"
      metric_name = "Errors"
      namespace   = "AWS/Lambda"
      period      = 300
      stat        = "Sum"
      dimensions  = {
        FunctionName = "my-function"
      }
    },
    {
      id          = "invocations"
      metric_name = "Invocations"
      namespace   = "AWS/Lambda"
      period      = 300
      stat        = "Sum"
      dimensions  = {
        FunctionName = "my-function"
      }
    }
  ]

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  threshold           = 5  # 5% error rate
  treat_missing_data  = "notBreaching"
  
  alarm_actions = [aws_sns_topic.alerts.arn]
  tags = {
    Environment = "Production"
    Service     = "API"
  }
}
```

## Input Variables

### Required Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `alarm_name` | Descriptive name for the alarm (must be unique within AWS account) | `string` | n/a | yes |
| `comparison_operator` | Arithmetic operation for comparing statistic and threshold | `string` | n/a | yes |
| `evaluation_periods` | Number of periods over which data is compared to threshold | `number` | n/a | yes |
| `threshold` | Value against which the statistic is compared | `number` | n/a | yes |

### Metric Configuration - Single Metric Mode

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `metric_name` | Name of the metric (required when not using metric_query) | `string` | `null` | no* |
| `namespace` | Namespace for the metric (required when not using metric_query) | `string` | `null` | no* |
| `period` | Period in seconds over which statistic is applied | `number` | `300` | no |
| `statistic` | Statistic to apply to the alarm's metric | `string` | `"Average"` | no |
| `dimensions` | Dimensions for the metric | `map(string)` | `{}` | no |

*Required when `use_metric_query` is `false`

### Metric Math Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `use_metric_query` | Enable metric math expressions | `bool` | `false` | no |
| `metric_query` | List of metric query objects for math expressions | `list(object)` | `[]` | no* |

*Required when `use_metric_query` is `true`

### Alarm Behavior Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `actions_enabled` | Whether actions should be executed during alarm state changes | `bool` | `true` | no |
| `alarm_actions` | Actions to execute when transitioning to ALARM state | `list(string)` | `[]` | no |
| `ok_actions` | Actions to execute when transitioning to OK state | `list(string)` | `[]` | no |
| `alarm_description` | Description for the alarm | `string` | `null` | no |
| `datapoints_to_alarm` | Number of datapoints that must be breaching to trigger alarm | `number` | `null` | no |
| `treat_missing_data` | How to handle missing data points | `string` | `"missing"` | no |

### Tagging Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `tags` | Tags to assign to the alarm | `map(string)` | `{}` | no |
| `default_tags` | Default tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `id` | The ID of the CloudWatch alarm |
| `arn` | The ARN of the CloudWatch alarm |
| `name` | The name of the CloudWatch alarm |
| `description` | The description of the CloudWatch alarm |
| `actions` | Map of actions configured for the alarm |
| `configuration` | Map of alarm configuration settings |
| `metric_details` | Details about the metric(s) being monitored |

## Metric Math Reference

CloudWatch metric math allows you to perform calculations on your metrics for more meaningful alarms:

### Common Metric Math Functions

- Basic operations: `+`, `-`, `*`, `/`, `^`
- Statistical functions: `AVG()`, `SUM()`, `MIN()`, `MAX()`, `STDDEV()`
- Rate functions: `RATE()`, `DIFF()`
- Special functions: `FILL()`, `ANOMALY_DETECTION_BAND()`

### Common Use Cases

1. **Percentages**: `(metric1 * 100) / metric2`
2. **Rate of change**: `RATE(metric)`
3. **Anomaly detection**: `ANOMALY_DETECTION_BAND(metric, 2)`
4. **Aggregation across resources**: `SUM([metric1, metric2, metric3])`
5. **Standard deviation/variance**: `STDDEV(metric)`

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.0, < 2.0.0 |
| aws | >= 5.75.0, < 6.0.0 |

## License

MIT

## Credits

Original module and metric math implementation guidance created with assistance from Claude AI (Anthropic).