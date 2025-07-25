# =============================================================================
# REACT APPLICATION INFRASTRUCTURE PROJECT
# =============================================================================
# This project demonstrates a complete CI/CD pipeline for deploying a React application
# to AWS using Terraform for infrastructure and Ansible for server provisioning.
# =============================================================================

## 📋 PROJECT OVERVIEW

This project automates the deployment of a React application to AWS infrastructure using:
- **Terraform** for infrastructure as code (IaC)
- **Ansible** for server provisioning and configuration
- **Docker** for containerized application deployment
- **GitHub Actions** for continuous integration and deployment

## 🏗️ ARCHITECTURE

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitHub Repo   │───▶│  GitHub Actions │───▶│   AWS Cloud     │
│                 │    │   CI/CD Pipeline│    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │                        │
                              ▼                        ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   Docker Hub    │    │   EC2 Instance  │
                       │   Image Push    │    │   (Amazon Linux)│
                       └─────────────────┘    └─────────────────┘
                                                       │
                                                       ▼
                                              ┌─────────────────┐
                                              │   Ansible       │
                                              │   Provisioning  │
                                              └─────────────────┘
                                                       │
                                                       ▼
                                              ┌─────────────────┐
                                              │   React App     │
                                              │   (Port 81)     │
                                              └─────────────────┘
```

## 📁 PROJECT STRUCTURE

```
andy/
├── 📁 ansible/                    # Ansible configuration and playbooks
│   ├── 📄 inventory.tpl          # Template for dynamic inventory generation
│   └── 📄 playbook.yml           # Server provisioning playbook
├── 📁 react-project/             # React application source code
│   ├── 📁 public/                # Static assets
│   ├── 📁 src/                   # React source code
│   ├── 📄 package.json           # Node.js dependencies
│   └── 📄 package-lock.json      # Locked dependency versions
├── 📁 backend/                   # Terraform backend configuration
├── 📁 .github/workflows/         # GitHub Actions CI/CD pipeline
├── 📄 main.tf                    # Main Terraform configuration
├── 📄 variables.tf               # Terraform input variables
├── 📄 locals.tf                  # Terraform local values
├── 📄 data.tf                    # Terraform data sources
├── 📄 provider.tf                # Terraform provider configuration
├── 📄 outputs.tf                 # Terraform output values
├── 📄 backend.tf                 # Terraform backend configuration
├── 📄 Dockerfile                 # Multi-stage Docker build
├── 📄 nginx.conf                 # Nginx web server configuration
├── 📄 inventory.tpl              # Ansible inventory template
└── 📄 README.md                  # This documentation file
```

## 🚀 QUICK START

### Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** installed (version >= 1.0)
3. **Ansible** installed (version >= 2.9)
4. **Docker** installed (for local testing)
5. **GitHub Account** with repository access

### Environment Setup

1. **Configure AWS Credentials**
   ```bash
   aws configure
   ```

2. **Set Required Environment Variables**
   ```bash
   export AWS_ACCESS_KEY_ID="your-access-key"
   export AWS_SECRET_ACCESS_KEY="your-secret-key"
   export AWS_DEFAULT_REGION="us-east-1"
   ```

### Deployment Steps

1. **Initialize Terraform**
   ```bash
   terraform init
   ```

2. **Plan the Deployment**
   ```bash
   terraform plan
   ```

3. **Apply the Infrastructure**
   ```bash
   terraform apply
   ```

4. **Access the Application**
   - Get the public IP from Terraform outputs
   - Open browser: `http://<public-ip>:81`

## 🔧 CONFIGURATION

### Terraform Variables

| Variable | Description | Default Value |
|----------|-------------|---------------|
| `region` | AWS region for deployment | `us-east-1` |
| `ami` | Amazon Machine Image ID | `ami-0150ccaf51ab55a51` |

### Customization

1. **Change AWS Region**
   ```bash
   terraform apply -var="region=us-west-2"
   ```

2. **Use Different AMI**
   ```bash
   terraform apply -var="ami=ami-12345678"
   ```

3. **Override Variables File**
   Create `terraform.tfvars`:
   ```hcl
   region = "eu-west-1"
   ami    = "ami-87654321"
   ```

## 🏛️ INFRASTRUCTURE COMPONENTS

### AWS Resources Created

1. **EC2 Instance**
   - Amazon Linux 2023
   - t2.micro or t3.micro (auto-selected based on availability)
   - Public IP for external access

2. **Security Group**
   - SSH access (port 22)
   - HTTP access (port 80)
   - Custom port access (port 81)

3. **Key Pair**
   - Auto-generated RSA key pair
   - Stored in AWS Secrets Manager
   - Local file for Ansible access

4. **Ansible Integration**
   - Dynamic inventory generation
   - Automated server provisioning

### Application Stack

1. **Docker Container**
   - Multi-stage build for optimization
   - Nginx web server
   - React application served on port 81

2. **Nginx Configuration**
   - React Router support
   - Static asset caching
   - Performance optimization

## 🔄 CI/CD PIPELINE

### GitHub Actions Workflow

The `.github/workflows/blank.yml` file defines the CI/CD pipeline:

1. **Build Stage**
   - Checkout code
   - Login to Docker Hub
   - Build and push Docker image

2. **Deploy Stage**
   - Initialize Terraform
   - Plan and apply infrastructure
   - Run Ansible provisioning

### Pipeline Triggers

- **Pull Request Merge**: Automatically deploys to production
- **Manual Trigger**: Available for testing and debugging

## 🛠️ DEVELOPMENT

### Local Development

1. **React Development**
   ```bash
   cd react-project
   npm install
   npm start
   ```

2. **Docker Testing**
   ```bash
   docker build -t react-app .
   docker run -p 81:81 react-app
   ```

3. **Terraform Testing**
   ```bash
   terraform plan
   terraform apply -target=aws_instance.amazonlinux
   ```

### Making Changes

1. **React Application**
   - Edit files in `react-project/src/`
   - Test locally with `npm start`
   - Commit and push to trigger CI/CD

2. **Infrastructure**
   - Modify Terraform files in root directory
   - Test with `terraform plan`
   - Apply changes with `terraform apply`

3. **Server Configuration**
   - Edit `ansible/playbook.yml`
   - Test with `ansible-playbook -i inventory.ini playbook.yml`

## 🔍 MONITORING AND TROUBLESHOOTING

### Useful Commands

1. **Check EC2 Instance Status**
   ```bash
   aws ec2 describe-instances --instance-ids <instance-id>
   ```

2. **SSH into Instance**
   ```bash
   ssh -i deployer-key.pem ec2-user@<public-ip>
   ```

3. **Check Docker Containers**
   ```bash
   docker ps
   docker logs react-app
   ```

4. **Check Nginx Status**
   ```bash
   sudo systemctl status nginx
   sudo nginx -t
   ```

### Common Issues

1. **SSH Connection Failed**
   - Verify security group allows port 22
   - Check key pair permissions: `chmod 400 deployer-key.pem`

2. **Application Not Accessible**
   - Verify security group allows port 81
   - Check Docker container status
   - Verify nginx configuration

3. **Terraform Errors**
   - Check AWS credentials
   - Verify region and AMI availability
   - Review Terraform logs

## 🧹 CLEANUP

### Destroy Infrastructure

```bash
terraform destroy
```

This will remove:
- EC2 instance
- Security group
- Key pair
- AWS Secrets Manager secret
- Local files (deployer-key.pem, inventory.ini)

### Manual Cleanup

If Terraform destroy fails, manually remove:
1. EC2 instance from AWS Console
2. Security group from AWS Console
3. Key pair from AWS Console
4. Secret from AWS Secrets Manager

## 📚 ADDITIONAL RESOURCES

- [Terraform Documentation](https://www.terraform.io/docs)
- [Ansible Documentation](https://docs.ansible.com)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2)
- [Docker Documentation](https://docs.docker.com)
- [React Documentation](https://reactjs.org/docs)

## 🤝 CONTRIBUTING

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 LICENSE

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 SUPPORT

For issues and questions:
1. Check the troubleshooting section
2. Review Terraform and Ansible logs
3. Create an issue in the GitHub repository

---

**Note**: This infrastructure is designed for development and testing. For production use, consider additional security measures, monitoring, and backup strategies.
