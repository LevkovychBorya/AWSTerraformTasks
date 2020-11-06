module "lambda" {
    source = "./modules/lambda"
    vpc_id = join(", ", data.aws_vpcs.elk_vpc.ids)
    internet_gateway_id = data.aws_internet_gateway.elk_ig.id
    public_subnet_cidr_block = var.public_subnet_cidr_block
    private_subnet_cidr_block = var.private_subnet_cidr_block
    availability_zone = var.availability_zone
    function_file_path = var.function_file_path
    tag_owner = "blevk"
}
/* module "lambda_config" {
    source = "./modules/lambda_config"
    function_name = var.function_name
    tag_owner = "blevk"
} */