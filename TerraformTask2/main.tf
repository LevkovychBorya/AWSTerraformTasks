# Subnets and stuff

locals {
  vpc_id = join(", ", data.aws_vpcs.elk_vpc.ids)
  /* oauth_creds = jsondecode(
    data.aws_secretsmanager_secret_version.github_OAuth.secret_string
  ) */
}
resource "aws_subnet" "elk_public_1a" {
  vpc_id     = local.vpc_id
  cidr_block = "172.30.51.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "blelk_public_1a"
    owner = "blevk"
  }
}
resource "aws_subnet" "elk_public_1b" {
  vpc_id     = local.vpc_id
  cidr_block = "172.30.52.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "blelk_public_1b"
    owner = "blevk"
  }
}
resource "aws_subnet" "elk_private_1a" {
  vpc_id     = local.vpc_id
  cidr_block = "172.30.53.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "blelk_private_1a"
    owner = "blevk"
  }
}
resource "aws_subnet" "elk_private_1b" {
  vpc_id     = local.vpc_id
  cidr_block = "172.30.54.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "blelk_private_1b"
    owner = "blevk"
  }
}
resource "aws_route_table" "elk_gw_route" {
  vpc_id = local.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.elk_ig.id
  }

  tags = {
    Name = "blelk_gw_route"
    owner = "blevk"
  }
}
resource "aws_route_table_association" "elk_public_1a_ass" {
  subnet_id      = aws_subnet.elk_public_1a.id
  route_table_id = aws_route_table.elk_gw_route.id
}
resource "aws_route_table_association" "elk_public_1b_ass" {
  subnet_id      = aws_subnet.elk_public_1b.id
  route_table_id = aws_route_table.elk_gw_route.id
}

# Create elasticsearch cluster

resource "aws_instance" "elasticsearh_master" {
  ami           = data.aws_ami.ubuntu_20.id
  instance_type = "t2.medium"
  vpc_security_group_ids = [aws_security_group.elasticsearch_securitygp.id]
  subnet_id = aws_subnet.elk_private_1a.id
  root_block_device {
    volume_type = "gp2"
    volume_size = "10"
    delete_on_termination = true
  }
  user_data = data.template_file.elastic_master_tmp.rendered
  
  tags = {
    Name = "blelk_elastic_master"
    owner = "blevk"
  }
}
resource "aws_instance" "elasticsearh_data_1" {
  ami           = data.aws_ami.ubuntu_20.id
  instance_type = "t2.medium"
  vpc_security_group_ids = [aws_security_group.elasticsearch_securitygp.id]
  subnet_id = aws_subnet.elk_private_1a.id
  root_block_device {
    volume_type = "gp2"
    volume_size = "10"
    delete_on_termination = true
  }
  user_data = data.template_file.elastic_data_1_tmp.rendered
  
  tags = {
    Name = "blelk_elastic_data_1"
    owner = "blevk"
  }
}
resource "aws_instance" "elasticsearh_data_2" {
  ami           = data.aws_ami.ubuntu_20.id
  instance_type = "t2.medium"
  vpc_security_group_ids = [aws_security_group.elasticsearch_securitygp.id]
  subnet_id = aws_subnet.elk_private_1a.id
  root_block_device {
    volume_type = "gp2"
    volume_size = "10"
    delete_on_termination = true
  }
  user_data = data.template_file.elastic_data_2_tmp.rendered
  
  tags = {
    Name = "blelk_elastic_data_2"
    owner = "blevk"
  }
}
resource "aws_security_group" "elasticsearch_securitygp" {
  name        = "blelk_elasticsearch_securitygp"
  description = "Security group for elasticsearch"
  vpc_id      = local.vpc_id

  ingress {
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
    security_groups = [aws_security_group.logstash_securitygp.id, aws_security_group.kibana_securitygp.id]
  }

  ingress {
    from_port   = 9300
    to_port     = 9305
    protocol    = "tcp"
    self = true
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "blelk_elasticsearch_securitygp"
    owner = "blevk"
  }
}

# Create logstash instances

resource "aws_instance" "logstash" {
  ami           = data.aws_ami.ubuntu_20.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.logstash_securitygp.id]
  subnet_id = aws_subnet.elk_private_1b.id
  root_block_device {
    volume_type = "gp2"
    volume_size = "8"
    delete_on_termination = true
  }
  user_data = data.template_file.logstash_tmp.rendered
  count = 2
  
  tags = {
    Name = format("blelk_logstash_%d", count.index + 1)
    owner = "blevk"
  }
}

resource "aws_security_group" "logstash_securitygp" {
  name        = "blelk_logstash_securitygp"
  description = "Security group for logstash"
  vpc_id      = local.vpc_id

  ingress {
    from_port   = 5044
    to_port     = 5044
    protocol    = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "blelk_logstash_securitygp"
    owner = "blevk"
  }
}

# Create kibana instance

resource "aws_instance" "kibana" {
  ami           = data.aws_ami.ubuntu_20.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.kibana_securitygp.id]
  subnet_id = aws_subnet.elk_public_1a.id
  associate_public_ip_address = true
  root_block_device {
    volume_type = "gp2"
    volume_size = "8"
    delete_on_termination = true
  }
  user_data = data.template_file.kibana_tmp.rendered
  
  tags = {
    Name = "blelk_kibana"
    owner = "blevk"
  }
}

resource "aws_security_group" "kibana_securitygp" {
  name        = "blelk_kibana_securitygp"
  description = "Security group for kibana"
  vpc_id      = local.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "blelk_kibana_securitygp"
    owner = "blevk"
  }
}

# Create log generator

resource "aws_instance" "apache" {
  ami           = data.aws_ami.ubuntu_20.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.apache_securitygp.id]
  subnet_id = aws_subnet.elk_public_1a.id
  associate_public_ip_address = true
  root_block_device {
    volume_type = "gp2"
    volume_size = "8"
    delete_on_termination = true
  }
  user_data = data.template_file.apache_tmp.rendered
  
  tags = {
    Name = "blelk_apache"
    owner = "blevk"
  }
}

resource "aws_security_group" "apache_securitygp" {
  name        = "blelk_apache_securitygp"
  description = "Security group for apache"
  vpc_id      = local.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "blelk_apache_securitygp"
    owner = "blevk"
  }
}

/* resource "aws_route53_zone" "local_DNS_zone" {
  name = "blevk.elk"

  vpc {
    vpc_id = local.vpc_id
  }

  tags = {
    Name = "blelk_zone"
    owner = "blevk"
  }
} */

# Create local DNS hosted zone records

resource "aws_route53_record" "elasticsearch_master_record" {
  zone_id = var.local_DNS_zone_id
  name    = var.master_DNS
  type    = "A"
  ttl     = "300"
  records = [aws_instance.elasticsearh_master.private_ip]
}

resource "aws_route53_record" "elasticsearch_data_1_record" {
  zone_id = var.local_DNS_zone_id
  name    = var.data_1_DNS
  type    = "A"
  ttl     = "300"
  records = [aws_instance.elasticsearh_data_1.private_ip]
}

resource "aws_route53_record" "elasticsearch_data_2_record" {
  zone_id = var.local_DNS_zone_id
  name    = var.data_2_DNS
  type    = "A"
  ttl     = "300"
  records = [aws_instance.elasticsearh_data_2.private_ip]
}

resource "aws_route53_record" "logstash_1_record" {
  zone_id = var.local_DNS_zone_id
  name    = var.logstash_1_DNS
  type    = "A"
  ttl     = "300"
  records = [aws_instance.logstash[0].private_ip]
}

resource "aws_route53_record" "logstash_2_record" {
  zone_id = var.local_DNS_zone_id
  name    = var.logstash_2_DNS
  type    = "A"
  ttl     = "300"
  records = [aws_instance.logstash[1].private_ip]
}

# Create Kibana public DNS record

resource "aws_route53_record" "kibana_record" {
  zone_id = var.public_DNS_zone_id
  name    = var.kibana_DNS
  type    = "A"
  ttl     = "300"
  records = [aws_instance.kibana.public_ip]
 }