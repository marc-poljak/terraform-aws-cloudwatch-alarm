################################################################################
# variables.tf - Module input variables
################################################################################

#------------------------------------------------------------------------------
# Required Configuration Variables
#------------------------------------------------------------------------------

variable "alarm_name" {
  type        = string
  description = "The descriptive name for the alarm. This name must be unique within the user's AWS account."

  validation {
    condition     = length(var.alarm_name) > 0
    error_message = "The alarm_name value cannot be empty."
  }
}

variable "comparison_operator" {
  type        = string
  description = "The arithmetic operation to use when comparing the specified statistic and threshold."

  validation {
    condition     = contains(["GreaterThanOrEqualToThreshold", "GreaterThanThreshold", "LessThanThreshold", "LessThanOrEqualToThreshold"], var.comparison_operator)
    error_message = "Valid values are: GreaterThanOrEqualToThreshold, GreaterThanThreshold, LessThanThreshold, LessThanOrEqualToThreshold."
  }
}

variable "evaluation_periods" {
  type        = number
  description = "The number of periods over which data is compared to the specified threshold."

  validation {
    condition     = var.evaluation_periods > 0
    error_message = "The evaluation_periods value must be greater than 0."
  }
}

variable "threshold" {
  type        = number
  description = "The value against which the specified statistic is compared."
}

#------------------------------------------------------------------------------
# Metric Configuration - Single Metric Mode
#------------------------------------------------------------------------------

variable "metric_name" {
  type        = string
  description = "The name of the metric associated with the alarm (required when not using metric_query)."
  default     = null
}

variable "namespace" {
  type        = string
  description = "The namespace for the metric associated with the alarm (required when not using metric_query)."
  default     = null
}

variable "period" {
  type        = number
  default     = 300
  description = "The period in seconds over which the specified statistic is applied."

  validation {
    condition     = var.period == null || contains([10, 30, 60, 300, 900, 1800, 3600, 21600, 86400], var.period)
    error_message = "Period must be one of: 10, 30, 60, 300, 900, 1800, 3600, 21600, 86400 seconds."
  }
}

variable "statistic" {
  type        = string
  default     = "Average"
  description = "The statistic to apply to the alarm's associated metric."

  validation {
    condition     = var.statistic == null || contains(["SampleCount", "Average", "Sum", "Minimum", "Maximum"], var.statistic)
    error_message = "Statistic must be one of: SampleCount, Average, Sum, Minimum, or Maximum."
  }
}

variable "dimensions" {
  type        = map(string)
  default     = {}
  description = "The dimensions for the metric associated with the alarm."
}

#------------------------------------------------------------------------------
# Metric Math Configuration
#------------------------------------------------------------------------------

variable "use_metric_query" {
  type        = bool
  default     = false
  description = "Set to true to use metric_query instead of simple metric specification."
}

variable "metric_query" {
  type = list(object({
    id          = string
    expression  = optional(string)
    label       = optional(string)
    return_data = optional(bool, false)

    # For metric specification
    metric_name = optional(string)
    namespace   = optional(string)
    period      = optional(number)
    stat        = optional(string)
    dimensions  = optional(map(string))
    unit        = optional(string)
  }))
  default     = []
  description = "Enables metric math expressions that query multiple metrics and perform math expressions."
}

#------------------------------------------------------------------------------
# Alarm Behavior Configuration
#------------------------------------------------------------------------------

variable "actions_enabled" {
  type        = bool
  default     = true
  description = "Indicates whether actions should be executed during any changes to the alarm state."
}

variable "alarm_actions" {
  type        = list(string)
  default     = []
  description = "The list of actions to execute when this alarm transitions into an ALARM state from any other state."
}

variable "ok_actions" {
  type        = list(string)
  default     = []
  description = "The list of actions to execute when this alarm transitions into an OK state from any other state."
}

variable "alarm_description" {
  type        = string
  default     = null
  description = "The description for the alarm."
}

variable "datapoints_to_alarm" {
  type        = number
  default     = null
  description = "The number of datapoints that must be breaching to trigger the alarm."

  validation {
    condition     = var.datapoints_to_alarm != null ? var.datapoints_to_alarm > 0 : true
    error_message = "When specified, datapoints_to_alarm must be greater than 0."
  }
}

variable "treat_missing_data" {
  type        = string
  default     = "missing"
  description = "Sets how this alarm handles missing data points."

  validation {
    condition     = contains(["missing", "ignore", "breaching", "notBreaching"], var.treat_missing_data)
    error_message = "Valid values are: missing, ignore, breaching, notBreaching."
  }
}

#------------------------------------------------------------------------------
# Tagging Configuration
#------------------------------------------------------------------------------

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Key-value map of tags to assign to the alarm."
}

variable "default_tags" {
  type        = map(string)
  default     = {}
  description = "Default tags to apply to all resources created by this module."
}