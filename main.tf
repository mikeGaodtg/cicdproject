terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Data source to check t2.micro availability.
data "aws_ec2_instance_type_offerings" "t2_micro" {
  filter {
    name   = "instance-type"
    values = ["t2.micro"]
  }
  location_type = "availability-zone"
}

# Data source to check t3.micro availability
data "aws_ec2_instance_type_offerings" "t3_micro" {
  filter {
    name   = "instance-type"
    values = ["t3.micro"]
  }
  location_type = "availability-zone"
}

# Local variable to determine instance type
locals {
  t2_micro_available = length(data.aws_ec2_instance_type_offerings.t2_micro.instance_types) > 0
  t3_micro_available = length(data.aws_ec2_instance_type_offerings.t3_micro.instance_types) > 0
  instance_type     = local.t2_micro_available ? "t2.micro" : (local.t3_micro_available ? "t3.micro" : "none")
}

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

output "instance_public_ip" {
  description = "Public IP of the instance."
  value       = aws_instance.amazonlinux.public_ip
}

output "selected_instance_type" {
  description = "The instance type that was selected."
  value       = local.instance_type
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "ami" {
  type    = string
  default = "ami-0150ccaf51ab55a51"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "your-terraform-state-bucket-mike-gao-andy-project"
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# main.tf
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket-mike-gao-andy-project"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

# Create key pair
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key2"
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


output "inventory_content" {
  value = local_file.ansible_inventory.content
}
