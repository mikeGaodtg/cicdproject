# =============================================================================
# TERRAFORM DATA SOURCES CONFIGURATION
# =============================================================================
# This file defines data sources that query AWS for information
# These data sources are used to make dynamic decisions about resource creation
# =============================================================================

# =============================================================================
# T2.MICRO INSTANCE TYPE AVAILABILITY CHECK
# =============================================================================
# Queries AWS to check if t2.micro instance type is available in the current region
# This data source is used by locals.tf to determine instance type availability
data "aws_ec2_instance_type_offerings" "t2_micro" {
  # Filter to only look for t2.micro instance type
  filter {
    name   = "instance-type"
    values = ["t2.micro"]
  }
  # Check availability across all availability zones in the region
  location_type = "availability-zone"
}

# =============================================================================
# T3.MICRO INSTANCE TYPE AVAILABILITY CHECK
# =============================================================================
# Queries AWS to check if t3.micro instance type is available in the current region
# This data source is used by locals.tf to determine instance type availability
# t3.micro is the newer generation of t2.micro with better performance
data "aws_ec2_instance_type_offerings" "t3_micro" {
  # Filter to only look for t3.micro instance type
  filter {
    name   = "instance-type"
    values = ["t3.micro"]
  }
  # Check availability across all availability zones in the region
  location_type = "availability-zone"
} 