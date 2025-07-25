# =============================================================================
# TERRAFORM LOCALS CONFIGURATION
# =============================================================================
# This file defines local values that are computed based on data sources
# These locals provide dynamic configuration that adapts to AWS availability
# =============================================================================

locals {
  # =============================================================================
  # INSTANCE TYPE AVAILABILITY CHECKS
  # =============================================================================
  # Check if t2.micro instance type is available in the current region
  # This is important because not all regions support all instance types
  t2_micro_available = length(data.aws_ec2_instance_type_offerings.t2_micro.instance_types) > 0
  
  # Check if t3.micro instance type is available in the current region
  # t3.micro is the newer generation of t2.micro with better performance
  t3_micro_available = length(data.aws_ec2_instance_type_offerings.t3_micro.instance_types) > 0
  
  # =============================================================================
  # INSTANCE TYPE SELECTION LOGIC
  # =============================================================================
  # Determine which instance type to use based on availability:
  # 1. Prefer t2.micro if available (free tier eligible)
  # 2. Fall back to t3.micro if t2.micro is not available
  # 3. Use "none" if neither is available (will cause deployment to fail)
  instance_type = local.t2_micro_available ? "t2.micro" : (local.t3_micro_available ? "t3.micro" : "none")
} 