# data.tf
data "aws_availability_zones" "available" {
  state = "available"
}

# locals.tf — garantit exactement 3 AZs
locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}