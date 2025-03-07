################################################################################
# validations.tf - Module validation checks using Terraform's precondition
################################################################################

# Validate the configuration based on the chosen mode
resource "terraform_data" "validations" {
  input = "CloudWatch module validation"

  # Combine all preconditions into a single lifecycle block
  lifecycle {
    # Check that we have valid metric configuration for single metric mode
    precondition {
      condition     = local.is_metric_math_mode || (var.metric_name != null && var.namespace != null)
      error_message = "When not using metric_query mode, both metric_name and namespace are required."
    }

    # Check that we have valid metric configuration for metric math mode
    precondition {
      condition     = !local.is_metric_math_mode || length(var.metric_query) > 0
      error_message = "When using metric_query mode, you must provide at least one entry in the metric_query list."
    }

    # Check that we have at least one return_data = true in metric math mode
    precondition {
      condition     = !local.is_metric_math_mode || anytrue([for q in var.metric_query : q.return_data == true])
      error_message = "When using metric_query mode, at least one query must have return_data set to true."
    }

    # Check that datapoints_to_alarm doesn't exceed evaluation_periods
    precondition {
      condition     = var.datapoints_to_alarm != null ? var.datapoints_to_alarm <= var.evaluation_periods : true
      error_message = "datapoints_to_alarm cannot be greater than evaluation_periods."
    }
  }
}