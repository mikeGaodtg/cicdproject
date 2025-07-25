# =============================================================================
# MAIN TERRAFORM CONFIGURATION
# =============================================================================
# This file defines the core infrastructure components:
# - EC2 instance for hosting the React application
# - Security group for network access control
# - SSH key pair for secure access
# - Ansible integration for application deployment
# =============================================================================

# =============================================================================
# EC2 INSTANCE RESOURCE
# =============================================================================
# Creates an Amazon Linux EC2 instance to host the React application
# The instance will be provisioned with Docker and the React app
resource "aws_instance" "amazonlinux" {
  # Use the AMI specified in variables (Amazon Linux 2023)
  ami           = var.ami
  
  # Use the instance type determined by locals (t2.micro or t3.micro)
  instance_type = local.instance_type
  
  # Attach the security group that allows SSH, HTTP, and port 81
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  
  # Use the SSH key pair for secure access
  key_name = aws_key_pair.deployer.key_name

  # =============================================================================
  # LIFECYCLE CONFIGURATION
  # =============================================================================
  # Ensures zero-downtime deployments and validates instance type availability
  lifecycle {
    # Create new instance before destroying old one (zero-downtime)
    create_before_destroy = true
    
    # Precondition to verify instance type availability
    # This prevents deployment if neither t2.micro nor t3.micro are available
    precondition {
      condition     = local.instance_type != "none"
      error_message = "Neither t2.micro nor t3.micro are available in the region."
    }
  }

  # =============================================================================
  # TIMEOUT CONFIGURATION
  # =============================================================================
  # Extended timeouts for instance creation/deletion to handle slow operations
  timeouts {
    create = "30m"  # Wait up to 30 minutes for instance creation
    delete = "30m"  # Wait up to 30 minutes for instance deletion
  }
}

# =============================================================================
# SECURITY GROUP RESOURCE
# =============================================================================
# Defines network access rules for the EC2 instance
# Controls which ports are open and from which sources
resource "aws_security_group" "allow_ssh" {
  description = "Allow SSH inbound traffic"

  # =============================================================================
  # INBOUND RULES (INGRESS)
  # =============================================================================
  
  # Rule 1: SSH Access (Port 22)
  # Allows SSH connections from anywhere (0.0.0.0/0)
  # This is needed for Ansible to provision the server
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow from anywhere (consider restricting in production)
  }

  # Rule 2: HTTP Access (Port 80)
  # Allows HTTP traffic for web access
  # This enables access to the React application via HTTP
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Rule 3: Custom Port Access (Port 81)
  # Allows access to port 81 where the React app runs
  # This is the port specified in the Dockerfile and nginx configuration
  ingress {
    description = "allow 81"
    from_port   = 81
    to_port     = 81
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # =============================================================================
  # OUTBOUND RULES (EGRESS)
  # =============================================================================
  # Allow all outbound traffic (needed for package installation, updates, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # All protocols
    cidr_blocks = ["0.0.0.0/0"]  # All destinations
  }

  # =============================================================================
  # TAGGING
  # =============================================================================
  tags = {
    Name = "allow_ssh"
  }
}

# =============================================================================
# SSH KEY PAIR RESOURCE
# =============================================================================
# Creates an AWS key pair for SSH access to the EC2 instance
# This key pair will be used by Ansible to connect to the server
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key3"  # Name of the key pair in AWS
  public_key = tls_private_key.pk.public_key_openssh  # Public key from generated private key
}

# =============================================================================
# PRIVATE KEY GENERATION
# =============================================================================
# Generates a new RSA private key for SSH access
# This key will be used to connect to the EC2 instance
resource "tls_private_key" "pk" {
  algorithm = "RSA"  # Use RSA encryption algorithm
  rsa_bits  = 4096   # Use 4096-bit key for enhanced security
}

# =============================================================================
# AWS SECRETS MANAGER INTEGRATION
# =============================================================================
# Stores the private key securely in AWS Secrets Manager
# This provides a secure way to store sensitive information

# Create a secret in AWS Secrets Manager to store the private key
resource "aws_secretsmanager_secret" "private_key" {
  name = "ec2-private-key"  # Name of the secret in AWS Secrets Manager
}

# Store the private key content in the secret
resource "aws_secretsmanager_secret_version" "private_key" {
  secret_id     = aws_secretsmanager_secret.private_key.id  # Reference to the secret
  secret_string = tls_private_key.pk.private_key_pem        # The actual private key content
}

# =============================================================================
# LOCAL PRIVATE KEY FILE
# =============================================================================
# Saves the private key locally for Ansible to use
# This file will be used by Ansible to SSH into the EC2 instance
resource "local_file" "private_key" {
  content  = tls_private_key.pk.private_key_pem  # Private key content
  filename = "${path.module}/deployer-key.pem"   # Local file path

  # Set proper permissions on the private key file (read-only for owner)
  provisioner "local-exec" {
    command = "chmod 400 ${path.module}/deployer-key.pem"
  }
}

# =============================================================================
# ANSIBLE INVENTORY GENERATION
# =============================================================================
# Creates a dynamic Ansible inventory file with the EC2 instance's IP address
# This file tells Ansible which server to connect to and how
resource "local_file" "ansible_inventory" {
  # Use templatefile function to generate inventory content
  # Replace ${ip_address} in the template with the actual EC2 public IP
  content = templatefile("${path.module}/ansible/inventory.tpl", {
    ip_address = aws_instance.amazonlinux.public_ip
  })
  filename = "${path.module}/inventory.ini"  # Save as inventory.ini in project root
}

# =============================================================================
# ANSIBLE PROVISIONING
# =============================================================================
# Runs the Ansible playbook to provision the EC2 instance
# This installs Docker, builds the React app, and starts the application
resource "null_resource" "ansible_provisioner" {
  # =============================================================================
  # DEPENDENCIES
  # =============================================================================
  # Ensure these resources are created before running Ansible
  depends_on = [
    aws_instance.amazonlinux,      # EC2 instance must exist
    local_file.private_key,        # Private key file must be created
    local_file.ansible_inventory   # Inventory file must be generated
  ]

  # =============================================================================
  # TRIGGERS
  # =============================================================================
  # Re-run Ansible when the instance IP changes
  # This ensures the playbook runs if the instance gets a new IP
  triggers = {
    instance_ip = aws_instance.amazonlinux.public_ip
  }

  # =============================================================================
  # PROVISIONING COMMAND
  # =============================================================================
  # Execute the Ansible playbook to provision the server
  provisioner "local-exec" {
    command = <<-EOF
      # Wait for SSH to become available on the EC2 instance
      # This ensures the instance is fully booted before running Ansible
      while ! nc -z ${aws_instance.amazonlinux.public_ip} 22; do
        echo "Waiting for SSH to become available..."
        sleep 5
      done
      
      # Run the Ansible playbook with the following options:
      # - ANSIBLE_HOST_KEY_CHECKING=False: Skip SSH host key verification
      # - -i inventory.ini: Use the generated inventory file
      # - --private-key deployer-key.pem: Use the generated private key
      # - ansible/playbook.yml: Path to the Ansible playbook
      # - -vv: Verbose output for debugging
      ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.ini --private-key deployer-key.pem ansible/playbook.yml -vv
    EOF
  }
}
