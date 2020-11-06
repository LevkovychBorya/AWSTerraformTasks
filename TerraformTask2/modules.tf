module "private_subnets" {
    source = "./modules/NAT"
    tag_owner = "blevk"
    public_subnet_id = aws_subnet.elk_public_1a.id
    vpc_id = local.vpc_id
    private_subnet_ids = [aws_subnet.elk_private_1a.id, aws_subnet.elk_private_1b.id]
}