# =============================================================================
# TERRAFORM PROVIDER CONFIGURATION
# =============================================================================
# This file configures the AWS provider for Terraform
# The provider is responsible for interacting with AWS APIs to create and manage resources
# =============================================================================

# =============================================================================
# TERRAFORM BLOCK CONFIGURATION
# =============================================================================
# Defines Terraform settings including required providers and their versions
terraform {
  # =============================================================================
  # REQUIRED PROVIDERS
  # =============================================================================
  # Specifies which providers are needed and their version constraints
  required_providers {
    # AWS Provider Configuration
    aws = {
      source  = "hashicorp/aws"  # Official AWS provider from HashiCorp
      version = "~> 6.0"         # Use version 6.x (compatible with 6.0 and above, but below 7.0)
      # The tilde (~>) operator allows patch-level updates within the same minor version
      # This ensures compatibility while allowing security and bug fixes
    }
  }
}

# =============================================================================
# AWS PROVIDER CONFIGURATION
# =============================================================================
# Configures the AWS provider with specific settings
provider "aws" {
  region = var.region  # Use the region specified in variables.tf
  # This allows the infrastructure to be deployed to different AWS regions
  # by simply changing the region variable
} 