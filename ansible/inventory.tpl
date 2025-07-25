# =============================================================================
# ANSIBLE INVENTORY TEMPLATE
# =============================================================================
# This template file is used by Terraform to generate a dynamic Ansible inventory
# The ${ip_address} placeholder will be replaced with the actual EC2 instance IP
# =============================================================================

# =============================================================================
# WEBSERVERS GROUP
# =============================================================================
# Defines a group of servers that will host web applications
# This group can be targeted specifically in Ansible playbooks
[webservers]
# The IP address will be dynamically inserted by Terraform
# ansible_user specifies the SSH user for connecting to the server
${ip_address} ansible_user=ec2-user 

# =============================================================================
# GLOBAL VARIABLES
# =============================================================================
# Variables that apply to all hosts in the inventory
[all:vars]
# Specifies the Python interpreter to use on the remote server
# This is important for Amazon Linux 2023 which uses Python 3
ansible_python_interpreter=/usr/bin/python3