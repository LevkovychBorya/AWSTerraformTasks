data "aws_vpcs" "elk_vpc" {
  tags = {
    Name = "L2-newcomers-vpc"
  }
}

data "aws_internet_gateway" "elk_ig" {
  filter {
    name   = "attachment.vpc-id"
    values = data.aws_vpcs.elk_vpc.ids
  }
}