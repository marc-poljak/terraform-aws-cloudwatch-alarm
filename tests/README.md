# CloudWatch Alarm Module Tests

This directory contains tests for the CloudWatch Alarm Terraform module using Terraform's built-in testing framework.

## Test Structure

The tests are organized into the following files:

1. `single_metric_tests.tftest.hcl` - Tests for the module's single metric alarm functionality
2. `metric_math_tests.tftest.hcl` - Tests for the module's metric math expressions functionality
3. `validation_tests.tftest.hcl` - Tests for input validation and error handling
4. `output_tests.tftest.hcl` - Tests for module outputs

## Running the Tests

To run all tests:

```bash
terraform test
```

To run specific test:

```bash
terraform test -filter="tests/single_metric_tests.tftest.hcl"
```