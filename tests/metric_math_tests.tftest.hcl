# Tests for the CloudWatch Alarm module in metric math mode

# Create AWS provider with mock values for testing
provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  s3_use_path_style           = true
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
}

# Test for basic metric math expression with required parameters
run "metric_math_basic" {
  command = plan

  # Basic metric math test - Error rate calculation
  variables {
    alarm_name          = "test-error-rate-alarm"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 3
    threshold           = 5 # 5% error rate threshold
    use_metric_query    = true

    # Define metric math queries for error rate calculation
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
          FunctionName = "test-function"
        }
      },
      {
        id          = "invocations"
        metric_name = "Invocations"
        namespace   = "AWS/Lambda"
        period      = 300
        stat        = "Sum"
        dimensions  = {
          FunctionName = "test-function"
        }
      }
    ]
  }

  # Assert that the plan will create the alarm resource
  assert {
    condition     = length(aws_cloudwatch_metric_alarm.this) == 1
    error_message = "CloudWatch alarm resource was not created for metric math mode"
  }

  # Verify we are using metric_query mode
  assert {
    condition     = length(aws_cloudwatch_metric_alarm.this.metric_query) > 0
    error_message = "Metric query should be used for metric math alarms"
  }

  # Verify the first query is the expression that returns data
  assert {
    condition     = aws_cloudwatch_metric_alarm.this.metric_query[0].id == "error_rate"
    error_message = "First metric query ID is incorrect"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.this.metric_query[0].expression == "errors * 100 / invocations"
    error_message = "Metric math expression is incorrect"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.this.metric_query[0].return_data == true
    error_message = "Return data flag should be true for the primary expression"
  }

  # Verify that metric_name and namespace are null when in metric math mode
  assert {
    condition     = aws_cloudwatch_metric_alarm.this.metric_name == null
    error_message = "Metric name should be null in metric math mode"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.this.namespace == null
    error_message = "Namespace should be null in metric math mode"
  }
}

# Test for metric math with more complex expressions and all options
run "metric_math_complex" {
  command = plan

  variables {
    alarm_name          = "test-complex-metric-math"
    alarm_description   = "Complex metric math example with multiple calculations"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 5
    threshold           = 90
    datapoints_to_alarm = 3
    treat_missing_data  = "notBreaching"
    use_metric_query    = true
    actions_enabled     = true
    alarm_actions       = ["arn:aws:sns:us-east-1:123456789012:test-alarm-topic"]
    ok_actions          = ["arn:aws:sns:us-east-1:123456789012:test-ok-topic"]

    # More complex metric math with multiple expressions
    metric_query = [
      {
        id          = "e1"
        expression  = "m1/(m1+m2)*100"
        label       = "Primary Percentage"
        return_data = true
      },
      {
        id          = "e2"
        expression  = "m2/(m1+m2)*100"
        label       = "Secondary Percentage"
        return_data = false
      },
      {
        id          = "m1"
        metric_name = "ConsumedReadCapacityUnits"
        namespace   = "AWS/DynamoDB"
        period      = 300
        stat        = "Sum"
        dimensions  = {
          TableName = "test-table"
        }
      },
      {
        id          = "m2"
        metric_name = "ConsumedWriteCapacityUnits"
        namespace   = "AWS/DynamoDB"
        period      = 300
        stat        = "Sum"
        dimensions  = {
          TableName = "test-table"
        }
      }
    ]

    tags = {
      Environment = "Test"
      Service     = "DynamoDB"
    }
  }

  # Assert that the plan will create the alarm resource
  assert {
    condition     = length(aws_cloudwatch_metric_alarm.this) == 1
    error_message = "CloudWatch alarm resource was not created for complex metric math"
  }

  # Verify we have the right number of metric queries
  assert {
    condition     = length(aws_cloudwatch_metric_alarm.this.metric_query) == 4
    error_message = "Incorrect number of metric queries"
  }

  # Check the returned data is from the right expression
  assert {
    condition     = [for q in aws_cloudwatch_metric_alarm.this.metric_query : q.return_data if q.id == "e1"][0] == true
    error_message = "Primary expression should return data"
  }

  # Check secondary expression doesn't return data
  assert {
    condition     = [for q in aws_cloudwatch_metric_alarm.this.metric_query : q.return_data if q.id == "e2"][0] == false
    error_message = "Secondary expression should not return data"
  }

  # Verify the alarm description is set correctly
  assert {
    condition     = aws_cloudwatch_metric_alarm.this.alarm_description == "Complex metric math example with multiple calculations"
    error_message = "Alarm description was not set correctly"
  }

  # Verify alarm actions
  assert {
    condition     = aws_cloudwatch_metric_alarm.this.alarm_actions[0] == "arn:aws:sns:us-east-1:123456789012:test-alarm-topic"
    error_message = "Alarm actions were not set correctly"
  }

  # Verify tags
  assert {
    condition     = aws_cloudwatch_metric_alarm.this.tags["Environment"] == "Test"
    error_message = "Environment tag was not set correctly"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.this.tags["Service"] == "DynamoDB"
    error_message = "Service tag was not set correctly"
  }
}

# Test for ANOMALY_DETECTION_BAND metric math
run "metric_math_anomaly_detection" {
  command = plan

  variables {
    alarm_name          = "test-anomaly-detection"
    comparison_operator = "LessThanLowerOrGreaterThanUpperThreshold"
    evaluation_periods  = 3
    threshold           = 0
    use_metric_query    = true

    # Anomaly detection band expression
    metric_query = [
      {
        id          = "anomaly"
        expression  = "ANOMALY_DETECTION_BAND(m1, 2)"
        label       = "CPUUtilization (Expected)"
        return_data = true
      },
      {
        id          = "m1"
        metric_name = "CPUUtilization"
        namespace   = "AWS/EC2"
        period      = 300
        stat        = "Average"
        dimensions  = {
          InstanceId = "i-0123456789abcdef0"
        }
      }
    ]
  }

  # Assert that the plan will create the alarm resource
  assert {
    condition     = length(aws_cloudwatch_metric_alarm.this) == 1
    error_message = "CloudWatch alarm resource was not created for anomaly detection"
  }

  # Verify the anomaly detection expression
  assert {
    condition     = aws_cloudwatch_metric_alarm.this.metric_query[0].expression == "ANOMALY_DETECTION_BAND(m1, 2)"
    error_message = "Anomaly detection expression is incorrect"
  }
}

# Test for using different periods in different metrics
run "metric_math_different_periods" {
  command = plan

  variables {
    alarm_name          = "test-different-periods"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 3
    threshold           = 10
    use_metric_query    = true

    # Default period that will be used when period is not specified
    period = 60

    metric_query = [
      {
        id          = "diff"
        expression  = "m2 - m1"
        label       = "Difference"
        return_data = true
      },
      {
        id          = "m1"
        metric_name = "CPUUtilization"
        namespace   = "AWS/EC2"
        # Uses default period of 60
        stat        = "Average"
        dimensions  = {
          InstanceId = "i-0123456789abcdef0"
        }
      },
      {
        id          = "m2"
        metric_name = "CPUUtilization"
        namespace   = "AWS/EC2"
        period      = 300 # Override with custom period
        stat        = "Average"
        dimensions  = {
          InstanceId = "i-0123456789abcdef0"
        }
      }
    ]
  }

  # Assert that the plan will create the alarm resource
  assert {
    condition     = length(aws_cloudwatch_metric_alarm.this) == 1
    error_message = "CloudWatch alarm resource was not created for different periods test"
  }

  # Verify the periods are set correctly for each metric
  assert {
    condition     = [for q in aws_cloudwatch_metric_alarm.this.metric_query : q.metric[0].period if q.id == "m1"][0] == 60
    error_message = "First metric should use default period of 60"
  }

  assert {
    condition     = [for q in aws_cloudwatch_metric_alarm.this.metric_query : q.metric[0].period if q.id == "m2"][0] == 300
    error_message = "Second metric should use custom period of 300"
  }
}

# Test for minimal metric math configuration
run "metric_math_minimal" {
  command = plan

  variables {
    alarm_name          = "test-minimal-metric-math"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 1
    threshold           = 100
    use_metric_query    = true

    # Minimal metric math with just one metric and direct reference
    metric_query = [
      {
        id          = "m1"
        metric_name = "CPUUtilization"
        namespace   = "AWS/EC2"
        period      = 300
        stat        = "Maximum"
        return_data = true
        dimensions  = {
          InstanceId = "i-0123456789abcdef0"
        }
      }
    ]
  }

  # Assert that the plan will create the alarm resource
  assert {
    condition     = length(aws_cloudwatch_metric_alarm.this) == 1
    error_message = "CloudWatch alarm resource was not created for minimal metric math"
  }

  # Verify we only have one metric query
  assert {
    condition     = length(aws_cloudwatch_metric_alarm.this.metric_query) == 1
    error_message = "Should have exactly one metric query"
  }

  # Verify this query returns data
  assert {
    condition     = aws_cloudwatch_metric_alarm.this.metric_query[0].return_data == true
    error_message = "Metric query should return data"
  }
}