# Tests for validations and negative cases in the CloudWatch Alarm module

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

# Test: Missing required parameters for single metric mode
run "missing_metric_name_and_namespace" {
  command = plan

  # Set variables with missing required parameters
  variables {
    alarm_name          = "test-missing-params"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 3
    threshold           = 80
    # Intentionally missing metric_name and namespace
    use_metric_query    = false
  }

  # Expect the plan to fail due to the precondition check
  expect_failures = [
    # The lifecycle precondition in validations.tf should fail
    {
      module   = module.missing_metric_name_and_namespace
      severity = "error"
      message_pattern = "When not using metric_query mode, both metric_name and namespace are required."
    }
  ]
}

# Test: Using metric_query mode without queries
run "metric_math_without_queries" {
  command = plan

  # Set variables with missing required parameters for metric math
  variables {
    alarm_name          = "test-empty-metric-query"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 3
    threshold           = 80
    use_metric_query    = true
    # Intentionally empty metric_query list
    metric_query        = []
  }

  # Expect the plan to fail due to the precondition check
  expect_failures = [
    # The lifecycle precondition in validations.tf should fail
    {
      module   = module.metric_math_without_queries
      severity = "error"
      message_pattern = "When using metric_query mode, you must provide at least one entry in the metric_query list."
    }
  ]
}

# Test: Metric math queries without return_data = true
run "metric_math_without_return_data" {
  command = plan

  # Set variables with metric queries that don't have return_data set to true
  variables {
    alarm_name          = "test-no-return-data"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 3
    threshold           = 80
    use_metric_query    = true

    # All queries have return_data = false
    metric_query = [
      {
        id          = "e1"
        expression  = "m1 + m2"
        label       = "Sum"
        return_data = false
      },
      {
        id          = "m1"
        metric_name = "CPUUtilization"
        namespace   = "AWS/EC2"
        period      = 300
        stat        = "Average"
        return_data = false
      },
      {
        id          = "m2"
        metric_name = "CPUUtilization"
        namespace   = "AWS/EC2"
        period      = 300
        stat        = "Maximum"
        return_data = false
      }
    ]
  }

  # Expect the plan to fail due to the precondition check
  expect_failures = [
    # The lifecycle precondition in validations.tf should fail
    {
      module   = module.metric_math_without_return_data
      severity = "error"
      message_pattern = "When using metric_query mode, at least one query must have return_data set to true."
    }
  ]
}

# Test: Invalid period value
run "invalid_period_value" {
  command = plan

  # Set variables with an invalid period value
  variables {
    alarm_name          = "test-invalid-period"
    metric_name         = "CPUUtilization"
    namespace           = "AWS/EC2"
    period              = 123 # Invalid - not one of the allowed values
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 3
    threshold           = 80
  }

  # Expect the plan to fail due to the validation check in variables.tf
  expect_failures = [
    {
      module   = module.invalid_period_value
      severity = "error"
      message_pattern = "Period must be one of: 10, 30, 60, 300, 900, 1800, 3600, 21600, 86400 seconds."
    }
  ]
}

# Test: Invalid statistic value
run "invalid_statistic_value" {
  command = plan

  # Set variables with an invalid statistic
  variables {
    alarm_name          = "test-invalid-statistic"
    metric_name         = "CPUUtilization"
    namespace           = "AWS/EC2"
    statistic           = "InvalidStatistic" # Invalid - not one of the allowed values
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 3
    threshold           = 80
  }

  # Expect the plan to fail due to the validation check in variables.tf
  expect_failures = [
    {
      module   = module.invalid_statistic_value
      severity = "error"
      message_pattern = "Statistic must be one of: SampleCount, Average, Sum, Minimum, or Maximum."
    }
  ]
}

# Test: Invalid comparison operator
run "invalid_comparison_operator" {
  command = plan

  # Set variables with an invalid comparison operator
  variables {
    alarm_name          = "test-invalid-operator"
    metric_name         = "CPUUtilization"
    namespace           = "AWS/EC2"
    comparison_operator = "EqualToThreshold" # Invalid - not one of the allowed values
    evaluation_periods  = 3
    threshold           = 80
  }

  # Expect the plan to fail due to the validation check in variables.tf
  expect_failures = [
    {
      module   = module.invalid_comparison_operator
      severity = "error"
      message_pattern = "Valid values are: GreaterThanOrEqualToThreshold, GreaterThanThreshold, LessThanThreshold, LessThanOrEqualToThreshold."
    }
  ]
}

# Test: Invalid treat_missing_data value
run "invalid_treat_missing_data" {
  command = plan

  # Set variables with an invalid treat_missing_data value
  variables {
    alarm_name          = "test-invalid-missing-data"
    metric_name         = "CPUUtilization"
    namespace           = "AWS/EC2"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 3
    threshold           = 80
    treat_missing_data  = "invalid" # Invalid - not one of the allowed values
  }

  # Expect the plan to fail due to the validation check in variables.tf
  expect_failures = [
    {
      module   = module.invalid_treat_missing_data
      severity = "error"
      message_pattern = "Valid values are: missing, ignore, breaching, notBreaching."
    }
  ]
}

# Test: Invalid evaluation_periods value (0)
run "invalid_evaluation_periods" {
  command = plan

  # Set variables with an invalid evaluation_periods value
  variables {
    alarm_name          = "test-invalid-evaluation-periods"
    metric_name         = "CPUUtilization"
    namespace           = "AWS/EC2"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 0 # Invalid - must be greater than 0
    threshold           = 80
  }

  # Expect the plan to fail due to the validation check in variables.tf
    expect_failures = [
      {
        module   = module.invalid_evaluation_periods
        severity = "error"
        message_pattern = "The evaluation_periods value must be greater than 0."
      }
    ]
  }
}

# Test: datapoints_to_alarm greater than evaluation_periods (invalid)
run "invalid_datapoints_to_alarm" {
  command = plan

  # Set variables with datapoints_to_alarm > evaluation_periods (invalid)
  variables {
    alarm_name          = "test-invalid-datapoints"
    metric_name         = "CPUUtilization"
    namespace           = "AWS/EC2"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 3
    datapoints_to_alarm = 5 # Invalid - cannot be greater than evaluation_periods
    threshold           = 80
  }

  # Expect the plan to fail due to the precondition check
  expect_failures = [
    {
      module   = module.invalid_datapoints_to_alarm
      severity = "error"
      message_pattern = "datapoints_to_alarm cannot be greater than evaluation_periods."
    }
  ]
}

# Test: Empty alarm name (invalid)
run "empty_alarm_name" {
  command = plan

  # Set variables with an empty alarm name
  variables {
    alarm_name          = "" # Invalid - cannot be empty
    metric_name         = "CPUUtilization"
    namespace           = "AWS/EC2"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 3
    threshold           = 80
  }

  # Expect the plan to fail due to the validation check in variables.tf
  expect_failures = [
    {
      module   = module.empty_alarm_name
      severity = "error"
      message_pattern = "The alarm_name value cannot be empty."
    }
  ]
}