# Tests for verifying CloudWatch Alarm module outputs

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

# Test for outputs in single metric mode
run "output_tests_single_metric" {
  command = apply

  variables {
    alarm_name          = "test-output-single-metric"
    alarm_description   = "Output test alarm for single metric"
    metric_name         = "CPUUtilization"
    namespace           = "AWS/EC2"
    statistic           = "Average"
    period              = 300
    dimensions          = {
      InstanceId = "i-1234567890abcdef0"
    }
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 3
    threshold           = 80
    datapoints_to_alarm = 2
    treat_missing_data  = "notBreaching"
    alarm_actions       = ["arn:aws:sns:us-east-1:123456789012:test-alarm-topic"]
    ok_actions          = ["arn:aws:sns:us-east-1:123456789012:test-ok-topic"]
    tags = {
      Environment = "Test"
    }
  }

  # Validate output types and values
  assert {
    condition     = output.id != null && output.id != ""
    error_message = "ID output should not be empty"
  }

  assert {
    condition     = output.arn != null && output.arn != ""
    error_message = "ARN output should not be empty"
  }

  assert {
    condition     = output.name == "test-output-single-metric"
    error_message = "Name output should match alarm_name input"
  }

  assert {
    condition     = output.description == "Output test alarm for single metric"
    error_message = "Description output should match alarm_description input"
  }

  # Test actions output map
  assert {
    condition     = output.actions.enabled == true
    error_message = "Actions enabled should be true"
  }

  assert {
    condition     = output.actions.alarm[0] == "arn:aws:sns:us-east-1:123456789012:test-alarm-topic"
    error_message = "Alarm actions output should match input"
  }

  assert {
    condition     = output.actions.ok[0] == "arn:aws:sns:us-east-1:123456789012:test-ok-topic"
    error_message = "OK actions output should match input"
  }

  # Test configuration output map
  assert {
    condition     = output.configuration.comparison_operator == "GreaterThanThreshold"
    error_message = "Comparison operator output should match input"
  }

  assert {
    condition     = output.configuration.evaluation_periods == 3
    error_message = "Evaluation periods output should match input"
  }

  assert {
    condition     = output.configuration.threshold == 80
    error_message = "Threshold output should match input"
  }

  assert {
    condition     = output.configuration.datapoints_to_alarm == 2
    error_message = "Datapoints to alarm output should match input"
  }

  assert {
    condition     = output.configuration.treat_missing_data == "notBreaching"
    error_message = "Treat missing data output should match input"
  }

  # Test metric details output
  assert {
    condition     = output.metric_details.type == "single_metric"
    error_message = "Metric type should be single_metric"
  }

  assert {
    condition     = output.metric_details.metric_name == "CPUUtilization"
    error_message = "Metric name output should match input"
  }

  assert {
    condition     = output.metric_details.namespace == "AWS/EC2"
    error_message = "Namespace output should match input"
  }

  assert {
    condition     = output.metric_details.statistic == "Average"
    error_message = "Statistic output should match input"
  }

  assert {
    condition     = output.metric_details.period == 300
    error_message = "Period output should match input"
  }

  assert {
    condition     = output.metric_details.dimensions.InstanceId == "i-1234567890abcdef0"
    error_message = "Dimensions output should match input"
  }

  assert {
    condition     = output.metric_details.metric_query == null
    error_message = "Metric query output should be null for single metric mode"
  }
}

# Test for outputs in metric math mode
run "output_tests_metric_math" {
  command = apply

  variables {
    alarm_name          = "test-output-metric-math"
    alarm_description   = "Output test alarm for metric math"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 3
    threshold           = 5
    use_metric_query    = true

    metric_query = [
      {
        id          = "e1"
        expression  = "m1 * 100 / m2"
        label       = "Percentage"
        return_data = true
      },
      {
        id          = "m1"
        metric_name = "CPUUtilization"
        namespace   = "AWS/EC2"
        period      = 300
        stat        = "Average"
      },
      {
        id          = "m2"
        metric_name = "CPUUtilization"
        namespace   = "AWS/EC2"
        period      = 300
        stat        = "Maximum"
      }
    ]
  }

  # Validate output types and values
  assert {
    condition     = output.name == "test-output-metric-math"
    error_message = "Name output should match alarm_name input"
  }

  # Test metric details output for metric math mode
  assert {
    condition     = output.metric_details.type == "metric_math"
    error_message = "Metric type should be metric_math"
  }

  assert {
    condition     = output.metric_details.metric_name == null
    error_message = "Metric name output should be null for metric math mode"
  }

  assert {
    condition     = output.metric_details.namespace == null
    error_message = "Namespace output should be null for metric math mode"
  }

  assert {
    condition     = output.metric_details.metric_query != null
    error_message = "Metric query output should not be null for metric math mode"
  }

  assert {
    condition     = length(output.metric_details.metric_query) == 3
    error_message = "Metric query output should have 3 entries"
  }

  assert {
    condition     = output.metric_details.metric_query[0].id == "e1"
    error_message = "First metric query ID output should match input"
  }

  assert {
    condition     = output.metric_details.metric_query[0].expression == "m1 * 100 / m2"
    error_message = "Metric query expression output should match input"
  }
}