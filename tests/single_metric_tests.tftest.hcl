# Tests for the CloudWatch Alarm module in single metric mode

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

# Test for basic single metric alarm with minimal required parameters
run "single_metric_basic" {
  # Basic single metric test - CPU Utilization alarm
  command = plan

  # Apply a plan that should succeed
  variables {
    alarm_name          = "test-cpu-utilization-alarm"
    metric_name         = "CPUUtilization"
    namespace           = "AWS/EC2"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 3
    threshold           = 80
  }

  # Assert that the plan will create the alarm resource
  assert {
    condition     = length(aws_cloudwatch_metric_alarm.this) == 1
    error_message = "CloudWatch alarm resource was not created"
  }

  # Validate single metric properties
  assert {
    condition     = aws_cloudwatch_metric_alarm.this.metric_name == "CPUUtilization"
    error_message = "Metric name was not set correctly"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.this.namespace == "AWS/EC2"
    error_message = "Namespace was not set correctly"
  }

  # Verify we are not using metric_query mode
  assert {
    condition     = length(aws_cloudwatch_metric_alarm.this.metric_query) == 0
    error_message = "Metric query should not be used for single metric alarms"
  }
}

# Test for single metric alarm with all optional parameters
run "single_metric_with_all_options" {
  command = plan

  variables {
    alarm_name          = "test-memory-utilization-alarm"
    alarm_description   = "Alarm when memory utilization exceeds 90%"
    metric_name         = "mem_used_percent"
    namespace           = "CWAgent"
    period              = 60
    statistic           = "Maximum"
    dimensions = {
      InstanceId = "i-0123456789abcdef0"
      InstanceType = "t3.micro"
    }
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 5
    threshold           = 90
    datapoints_to_alarm = 3
    treat_missing_data  = "breaching"
    actions_enabled     = true
    alarm_actions       = ["arn:aws:sns:us-east-1:123456789012:test-alarm-topic"]
    ok_actions          = ["arn:aws:sns:us-east-1:123456789012:test-ok-topic"]
    tags = {
      Environment = "Test"
      Purpose     = "Module Testing"
    }
    default_tags = {
      ManagedBy = "Terraform"
    }
  }

  # Assert that the plan will create the alarm resource
  assert {
    condition     = length(aws_cloudwatch_metric_alarm.this) == 1
    error_message = "CloudWatch alarm resource was not created"
  }

  # Validate alarm properties
  assert {
    condition     = aws_cloudwatch_metric_alarm.this.alarm_description == "Alarm when memory utilization exceeds 90%"
    error_message = "Alarm description was not set correctly"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.this.period == 60
    error_message = "Period was not set correctly"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.this.statistic == "Maximum"
    error_message = "Statistic was not set correctly"
  }

  # Validate dimensions are set properly
  assert {
    condition     = aws_cloudwatch_metric_alarm.this.dimensions["InstanceId"] == "i-0123456789abcdef0"
    error_message = "Instance ID dimension was not set correctly"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.this.dimensions["InstanceType"] == "t3.micro"
    error_message = "Instance Type dimension was not set correctly"
  }

  # Validate alarm behavior configuration
  assert {
    condition     = aws_cloudwatch_metric_alarm.this.datapoints_to_alarm == 3
    error_message = "Datapoints to alarm was not set correctly"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.this.treat_missing_data == "breaching"
    error_message = "Treat missing data was not set correctly"
  }

  # Validate actions
  assert {
    condition     = aws_cloudwatch_metric_alarm.this.alarm_actions[0] == "arn:aws:sns:us-east-1:123456789012:test-alarm-topic"
    error_message = "Alarm actions were not set correctly"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.this.ok_actions[0] == "arn:aws:sns:us-east-1:123456789012:test-ok-topic"
    error_message = "OK actions were not set correctly"
  }

  # Validate tags
  assert {
    condition     = aws_cloudwatch_metric_alarm.this.tags["Environment"] == "Test"
    error_message = "Environment tag was not set correctly"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.this.tags["ManagedBy"] == "Terraform"
    error_message = "ManagedBy tag was not set correctly"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.this.tags["Name"] == "test-memory-utilization-alarm"
    error_message = "Name tag was not set correctly"
  }
}

# Test period validation - should choose a valid period value
run "single_metric_period_validation" {
  command = plan

  variables {
    alarm_name          = "test-period-validation"
    metric_name         = "CPUUtilization"
    namespace           = "AWS/EC2"
    period              = 300 # Valid period
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 2
    threshold           = 75
  }

  # Make sure the plan succeeds
  assert {
    condition     = length(aws_cloudwatch_metric_alarm.this) == 1
    error_message = "CloudWatch alarm resource was not created with valid period"
  }

  # Validate period is set correctly
  assert {
    condition     = aws_cloudwatch_metric_alarm.this.period == 300
    error_message = "Period was not set to the expected value of 300"
  }
}

# Test statistic validation - should choose a valid statistic
run "single_metric_statistic_validation" {
  command = plan

  variables {
    alarm_name          = "test-statistic-validation"
    metric_name         = "CPUUtilization"
    namespace           = "AWS/EC2"
    statistic           = "Maximum" # Valid statistic
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 2
    threshold           = 75
  }

  # Make sure the plan succeeds
  assert {
    condition     = length(aws_cloudwatch_metric_alarm.this) == 1
    error_message = "CloudWatch alarm resource was not created with valid statistic"
  }

  # Validate statistic is set correctly
  assert {
    condition     = aws_cloudwatch_metric_alarm.this.statistic == "Maximum"
    error_message = "Statistic was not set to the expected value of Maximum"
  }
}

# Test edge case: minimum evaluation period
run "single_metric_minimum_evaluation_period" {
  command = plan

  variables {
    alarm_name          = "test-min-evaluation-period"
    metric_name         = "CPUUtilization"
    namespace           = "AWS/EC2"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 1 # Minimum allowed value
    threshold           = 80
  }

  # Assert that the plan will create the alarm resource
  assert {
    condition     = length(aws_cloudwatch_metric_alarm.this) == 1
    error_message = "CloudWatch alarm resource was not created with minimum evaluation period"
  }

  # Validate minimum evaluation period is set correctly
  assert {
    condition     = aws_cloudwatch_metric_alarm.this.evaluation_periods == 1
    error_message = "Evaluation periods was not set to minimum value of 1"
  }
}

# Test missing data behavior options
run "single_metric_missing_data_behavior" {
  command = plan

  variables {
    alarm_name          = "test-missing-data-behavior"
    metric_name         = "CPUUtilization"
    namespace           = "AWS/EC2"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 3
    threshold           = 80
    treat_missing_data  = "notBreaching" # Test a specific missing data behavior
  }

  # Assert that the plan will create the alarm resource
  assert {
    condition     = length(aws_cloudwatch_metric_alarm.this) == 1
    error_message = "CloudWatch alarm resource was not created with custom missing data behavior"
  }

  # Validate missing data behavior is set correctly
  assert {
    condition     = aws_cloudwatch_metric_alarm.this.treat_missing_data == "notBreaching"
    error_message = "Missing data behavior was not set to notBreaching"
  }
}