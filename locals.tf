locals {
  t2_micro_available = length(data.aws_ec2_instance_type_offerings.t2_micro.instance_types) > 0
  t3_micro_available = length(data.aws_ec2_instance_type_offerings.t3_micro.instance_types) > 0
  instance_type     = local.t2_micro_available ? "t2.micro" : (local.t3_micro_available ? "t3.micro" : "none")
} 