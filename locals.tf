################################################################################
# locals.tf - Local values for module logic
################################################################################

locals {
  # Determine if we're using metric math mode
  is_metric_math_mode = var.use_metric_query

  # Enhanced metric queries with additional derived properties
  metric_queries = [
    for query in var.metric_query : {
      id          = query.id
      expression  = query.expression
      label       = query.label
      return_data = query.return_data

      # Determine if this query contains a metric (not just an expression)
      has_metric  = query.metric_name != null

      # Metric properties (only used if has_metric is true)
      metric_name = query.metric_name
      namespace   = query.namespace
      period      = query.period != null ? query.period : var.period
      stat        = query.stat
      unit        = query.unit
      dimensions  = query.dimensions != null ? query.dimensions : {}
    }
  ]

  # Validate that we have appropriate configuration for the chosen mode
  validate_single_metric = (
    !local.is_metric_math_mode &&
    var.metric_name != null &&
    var.namespace != null
  )

  validate_metric_math = (
    local.is_metric_math_mode &&
    length(var.metric_query) > 0
  )
}