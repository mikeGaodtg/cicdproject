output "instance_public_ip" {
  description = "Public IP of the instance."
  value       = aws_instance.amazonlinux.public_ip
}

output "selected_instance_type" {
  description = "The instance type that was selected."
  value       = local.instance_type
}

output "inventory_content" {
  value = local_file.ansible_inventory.content
} 