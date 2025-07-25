resource "aws_instance" "amazonlinux" {
  ami           = var.ami
  instance_type = local.instance_type
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  key_name = aws_key_pair.deployer.key_name

  lifecycle {
    create_before_destroy = true
    
    # Precondition to verify instance type availability
    precondition {
      condition     = local.instance_type != "none"
      error_message = "Neither t2.micro nor t3.micro are available in the region."
    }
  }

  timeouts {
    create = "30m"
    delete = "30m"
  }
}

resource "aws_security_group" "allow_ssh" {
 
  description = "Allow SSH inbound traffic"

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    description = "allow 81"
    from_port   = 81
    to_port     = 81
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

# Create key pair
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key3"
  public_key = tls_private_key.pk.public_key_openssh
}

# Generate private key
resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create secret in AWS Secrets Manager
resource "aws_secretsmanager_secret" "private_key" {
  name = "ec2-private-key"
}

# Store private key in Secrets Manager
resource "aws_secretsmanager_secret_version" "private_key" {
  secret_id     = aws_secretsmanager_secret.private_key.id
  secret_string = tls_private_key.pk.private_key_pem
}

# Save private key locally
resource "local_file" "private_key" {
  content  = tls_private_key.pk.private_key_pem
  filename = "${path.module}/deployer-key.pem"

  provisioner "local-exec" {
    command = "chmod 400 ${path.module}/deployer-key.pem"
  }
}

# Create Ansible inventory file
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    ip_address = aws_instance.amazonlinux.public_ip
  })
  filename = "${path.module}/inventory.ini"
}

# Run Ansible playbook
resource "null_resource" "ansible_provisioner" {
  depends_on = [
    aws_instance.amazonlinux,
    local_file.private_key,
    local_file.ansible_inventory
  ]

  # Add triggers to ensure re-run when IP changes 
  triggers = {
    instance_ip = aws_instance.amazonlinux.public_ip
  }

  provisioner "local-exec" {
    command = <<-EOF
      while ! nc -z ${aws_instance.amazonlinux.public_ip} 22; do
        echo "Waiting for SSH to become available..."
        sleep 5
      done
      ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.ini --private-key deployer-key.pem playbook.yml -vv
    EOF
  }
}
