# =============================================================================
# TERRAFORM OUTPUTS CONFIGURATION
# =============================================================================
# This file defines output values that are displayed after Terraform operations
# These outputs provide useful information about the created infrastructure
# =============================================================================

# =============================================================================
# EC2 INSTANCE PUBLIC IP OUTPUT
# =============================================================================
# Displays the public IP address of the created EC2 instance
# This IP can be used to access the React application via web browser
output "instance_public_ip" {
  description = "Public IP of the instance."
  value       = aws_instance.amazonlinux.public_ip
  # This output is useful for:
  # - Accessing the application: http://<public_ip>:81
  # - SSH access: ssh -i deployer-key.pem ec2-user@<public_ip>
  # - Documentation and troubleshooting
}

# =============================================================================
# SELECTED INSTANCE TYPE OUTPUT
# =============================================================================
# Shows which instance type was actually selected based on availability
# This helps verify that the instance type selection logic worked correctly
output "selected_instance_type" {
  description = "The instance type that was selected."
  value       = local.instance_type
  # This output helps confirm:
  # - Whether t2.micro or t3.micro was chosen
  # - If the fallback logic worked as expected
  # - Cost implications (t2.micro is free tier eligible)
}

# =============================================================================
# ANSIBLE INVENTORY CONTENT OUTPUT
# =============================================================================
# Displays the content of the generated Ansible inventory file
# This is useful for debugging Ansible connectivity issues
output "inventory_content" {
  value = local_file.ansible_inventory.content
  # This output shows:
  # - The actual IP address that Ansible will connect to
  # - The SSH user and Python interpreter settings
  # - Helps verify that the inventory generation worked correctly
} 