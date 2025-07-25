# =============================================================================
# TERRAFORM VARIABLES CONFIGURATION
# =============================================================================
# This file defines input variables that can be customized when deploying
# the infrastructure. These variables allow for flexibility and reusability
# across different environments and regions.
# =============================================================================

# =============================================================================
# AWS REGION VARIABLE
# =============================================================================
# Specifies the AWS region where all resources will be created
# This affects the location of EC2 instances, security groups, and other AWS resources
variable "region" {
  type    = string
  default = "us-east-1"  # Default to US East (N. Virginia) region
  # You can override this by setting TF_VAR_region environment variable
  # or by creating a terraform.tfvars file
}

# =============================================================================
# AMI VARIABLE
# =============================================================================
# Specifies the Amazon Machine Image (AMI) ID for the EC2 instance
# This determines the operating system and pre-installed software on the instance
variable "ami" {
  type    = string
  default = "ami-0150ccaf51ab55a51"  # Amazon Linux 2023 AMI for us-east-1
  # This AMI provides a stable, secure, and high-performance Linux environment
  # It's optimized for AWS and includes AWS CLI and other AWS tools
  # 
  # To find AMI IDs for different regions:
  # 1. Go to AWS Console > EC2 > AMI Catalog
  # 2. Search for "Amazon Linux 2023"
  # 3. Copy the AMI ID for your desired region
}
