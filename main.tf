resource "aws_ecr_repository" "ecr_repository" {
  name  = "ghost-app-repo"
}

# Data source to get the default VPC
data "aws_vpc" "default" {
  default = true
}

# Data source to get the first default subnet
data "aws_subnet" "subnet_1" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  # You can also specify the availability zone if needed
  filter {
    name   = "availability-zone"
    values = ["us-east-1a"]  # Adjust to your preferred AZ
  }
}

# Data source to get the second default subnet
data "aws_subnet" "subnet_2" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "availability-zone"
    values = ["us-east-1b"]  # Adjust to your preferred AZ
  }
}


