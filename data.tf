# Data source to check t2.micro availability
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