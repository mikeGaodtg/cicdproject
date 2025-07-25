terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket-mike-gao-andy-projects"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
} 