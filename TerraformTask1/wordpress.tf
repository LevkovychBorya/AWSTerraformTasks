#--------------- Task #1 ✔------------------------#

#Create 6 subnets 2 public 4 private.

resource "aws_subnet" "blevk_wordpress_public_1a" {
  vpc_id     = var.vpc_id
  cidr_block = "172.30.31.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "blevk_wordpress_public_1a"
    owner = "blevk"
  }
}

resource "aws_subnet" "blevk_wordpress_public_1b" {
  vpc_id     = var.vpc_id
  cidr_block = "172.30.32.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "blevk_wordpress_public_1b"
    owner = "blevk"
  }
}

resource "aws_subnet" "blevk_wordpress_private_1_1a" {
  vpc_id     = var.vpc_id
  cidr_block = "172.30.33.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "blevk_wordpress_private_1_1a"
    owner = "blevk"
  }
}

resource "aws_subnet" "blevk_wordpress_private_1_1b" {
  vpc_id     = var.vpc_id
  cidr_block = "172.30.34.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "blevk_wordpress_private_1_1b"
    owner = "blevk"
  }
}

resource "aws_subnet" "blevk_wordpress_private_2_1a" {
  vpc_id     = var.vpc_id
  cidr_block = "172.30.35.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "blevk_wordpress_private_2_1a"
    owner = "blevk"
  }
}

resource "aws_subnet" "blevk_wordpress_private_2_1b" {
  vpc_id     = var.vpc_id
  cidr_block = "172.30.36.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "blevk_wordpress_private_2_1b"
    owner = "blevk"
  }
}

# Creating NAT gateway and routes.

resource "aws_eip" "blevk_wordpress_eip" {
  vpc      = true

  tags = {
    Name = "blevk_wordpress_eip"
    owner = "blevk"
  }
}

resource "aws_nat_gateway" "blevk_wordpress_nat_gw" {
  allocation_id = aws_eip.blevk_wordpress_eip.id
  subnet_id     = aws_subnet.blevk_wordpress_public_1a.id

  tags = {
    Name = "blevk_wordpress_nat_gw"
    owner = "blevk"
  }
}

resource "aws_route_table" "blevk_wordpress_private_route" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.blevk_wordpress_nat_gw.id
  }

  tags = {
    Name = "blevk_wordpress_private_route"
    owner = "blevk"
  }
}

resource "aws_route_table" "blevk_wordpress_public_route" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.gw_id
  }

  tags = {
    Name = "blevk_wordpress_public_route"
    owner = "blevk"
  }
}

# Associations

resource "aws_route_table_association" "blevk_wordpress_public_1a_ass" {
  subnet_id      = aws_subnet.blevk_wordpress_public_1a.id
  route_table_id = aws_route_table.blevk_wordpress_public_route.id
}

resource "aws_route_table_association" "blevk_wordpress_public_1b_ass" {
  subnet_id      = aws_subnet.blevk_wordpress_public_1b.id
  route_table_id = aws_route_table.blevk_wordpress_public_route.id
}

resource "aws_route_table_association" "blevk_wordpress_private_1_1a_ass" {
  subnet_id      = aws_subnet.blevk_wordpress_private_1_1a.id
  route_table_id = aws_route_table.blevk_wordpress_private_route.id
}

resource "aws_route_table_association" "blevk_wordpress_private_1_1b_ass" {
  subnet_id      = aws_subnet.blevk_wordpress_private_1_1b.id
  route_table_id = aws_route_table.blevk_wordpress_private_route.id
}

resource "aws_route_table_association" "blevk_wordpress_private_2_1a_ass" {
  subnet_id      = aws_subnet.blevk_wordpress_private_2_1a.id
  route_table_id = aws_route_table.blevk_wordpress_private_route.id
}

resource "aws_route_table_association" "blevk_wordpress_private_2_1b_ass" {
  subnet_id      = aws_subnet.blevk_wordpress_private_2_1b.id
  route_table_id = aws_route_table.blevk_wordpress_private_route.id
}

#--------------- Task #2 ✔------------------------#

resource "aws_db_instance" "blevk_wordpress_db" {
  allocated_storage       = 10
  storage_type            = "gp2"
  engine                  = "mysql"
  engine_version          = "8.0.20"
  instance_class          = "db.t2.micro"
  name                    = "wordpressdb"
  identifier              = "blevkwordpressdb"
  username                = var.username
  password                = var.password
  db_subnet_group_name    = aws_db_subnet_group.blevk_wordpress_subnetgp.id
  vpc_security_group_ids  = [aws_security_group.blevk_wordpress_db_securitygp.id]
  skip_final_snapshot     = true
  multi_az                = true
  backup_retention_period = 3

  tags = {
    Name = "blevk_wordpress_db"
    owner = "blevk"
  }
}

resource "aws_db_subnet_group" "blevk_wordpress_subnetgp" {
  name       = "blevk_wordpress_subnetgp"
  description = "Subnet group for wordpress task"
  subnet_ids = [aws_subnet.blevk_wordpress_private_2_1a.id,
  aws_subnet.blevk_wordpress_private_2_1b.id]

  tags = {
    Name = "blevk_wordpress_subnetgp"
    owner = "blevk"
  }
}

resource "aws_security_group" "blevk_wordpress_db_securitygp" {
  name        = "blevk_wordpress_db_securitygp"
  description = "Security group for wordpress task"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.blevk_wordpress_ec2_securitygp.id]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "blevk_wordpress_db_securitygp"
    owner = "blevk"
  }
}

#--------------- Task #3 ✔------------------------#

resource "aws_efs_file_system" "blevk_wordpress_efs" {
  creation_token = "blevk_wordpress_efs"

  tags = {
    Name = "blevk_wordpress_efs"
    owner = "blevk"
  }
}

resource "aws_efs_mount_target" "blevk_wordpress_efs_mount_1a" {
  file_system_id = aws_efs_file_system.blevk_wordpress_efs.id
  security_groups = [aws_security_group.blevk_wordpress_efs_securitygp.id]
  subnet_id      = aws_subnet.blevk_wordpress_private_1_1a.id
}

resource "aws_efs_mount_target" "blevk_wordpress_efs_mount_1b" {
  file_system_id = aws_efs_file_system.blevk_wordpress_efs.id
  security_groups = [aws_security_group.blevk_wordpress_efs_securitygp.id]
  subnet_id      = aws_subnet.blevk_wordpress_private_1_1b.id
}

resource "aws_security_group" "blevk_wordpress_efs_securitygp" {
  name        = "blevk_wordpress_efs_securitygp"
  description = "Security group for wordpress task"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    security_groups = [aws_security_group.blevk_wordpress_ec2_securitygp.id]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "blevk_wordpress_efs_securitygp"
    owner = "blevk"
  }
}

#--------------- Task #4 ✔------------------------#

resource "aws_autoscaling_group" "blevk_wordpress_autoscalinggp" {
  name_prefix               = "blevk_wordpress_autoscalinggp"
  max_size                  = 3
  min_size                  = 0
  health_check_type         = "EC2"
  health_check_grace_period = 300
  desired_capacity          = 1
  target_group_arns         = [aws_lb_target_group.blevk_wordpress_targetgroup.arn]
  #vpc_zone_identifier       = [aws_subnet.blevk_wordpress_private_1_1a.id, aws_subnet.blevk_wordpress_private_1_1b.id]
  vpc_zone_identifier       = [aws_subnet.blevk_wordpress_public_1a.id, aws_subnet.blevk_wordpress_public_1b.id]
  launch_configuration      = aws_launch_configuration.blevk_wordpress_launchcfg.name

  lifecycle {
      create_before_destroy = true
    }

  tags = [
  {
    "key"   = "Name"
    "value" = "blevk_wordpress_ec2"
    "propagate_at_launch" = true
    },
    {
    "key"   = "owner"
    "value" = "blevk"
    "propagate_at_launch" = true
  }]
}

resource "aws_launch_configuration" "blevk_wordpress_launchcfg" {
  name_prefix   = "blevk_wordpress_launchcfg"
  image_id      = var.image_id
  instance_type = "t2.micro"
  security_groups = [aws_security_group.blevk_wordpress_ec2_securitygp.id]
  associate_public_ip_address = true
  key_name = "blevk_pem"
  root_block_device {
    volume_type = "gp2"
    volume_size = "10"
    delete_on_termination = true
  }
  user_data = data.template_file.config.rendered

  lifecycle {
    create_before_destroy = true
  }
}

data "template_file" "config" {
  template = file("config.tpl")
  vars = {
  efs_id = aws_efs_file_system.blevk_wordpress_efs.id
  DB_NAME = aws_db_instance.blevk_wordpress_db.name
  DB_USER = aws_db_instance.blevk_wordpress_db.username
  DB_PASSWORD = aws_db_instance.blevk_wordpress_db.password
  DB_HOST = aws_db_instance.blevk_wordpress_db.address
  LOGSTASH_1_DNS = var.LOGSTASH_1_DNS
  LOGSTASH_2_DNS = var.LOGSTASH_2_DNS
 }
}

resource "aws_security_group" "blevk_wordpress_ec2_securitygp" {
  name        = "blevk_wordpress_ec2_securitygp"
  description = "Security group for wordpress task"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.blevk_wordpress_alb_securitygp.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "blevk_wordpress_ec2_securitygp"
    owner = "blevk"
  }
}

#--------------- Task #5 X------------------------#

resource "aws_lb" "blevk_wordpress_alb" {
  name               = "blevkwordpress"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.blevk_wordpress_alb_securitygp.id]
  subnets            = [aws_subnet.blevk_wordpress_public_1a.id,
  aws_subnet.blevk_wordpress_public_1b.id]

  tags = {
    Name = "blevk_wordpress_alb"
    owner = "blevk"
  }
}

resource "aws_lb_target_group" "blevk_wordpress_targetgroup" {
  name     = "blevkwordpress"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  slow_start = 600
}

resource "aws_lb_listener" "blevk_wordpress_alb_listen80" {
  load_balancer_arn = aws_lb.blevk_wordpress_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "blevk_wordpress_alb_listen443" {
  load_balancer_arn = aws_lb.blevk_wordpress_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blevk_wordpress_targetgroup.arn
  }
}

resource "aws_acm_certificate" "blevk_wordpress_acm_cert" {
  domain_name       = "bwordpress.support-coe.com"
  validation_method = "DNS"

  tags = {
    Name = "blevk_wordpress_acm_cert"
    owner = "blevk"
  }
}

resource "aws_route53_record" "blevk_wordpress_route53_validate" {
  for_each = {
    for dvo in aws_acm_certificate.blevk_wordpress_acm_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.zone_id
}

resource "aws_acm_certificate_validation" "blevk_wordpress_acm_cert_valid" {
  certificate_arn         = aws_acm_certificate.blevk_wordpress_acm_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.blevk_wordpress_route53_validate : record.fqdn]
}

resource "aws_security_group" "blevk_wordpress_alb_securitygp" {
  name        = "blevk_wordpress_alb_securitygp"
  description = "Security group for wordpress task"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = ["80", "443"]
    content {
      from_port = ingress.value
      to_port = ingress.value
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "blevk_wordpress_alb_securitygp"
    owner = "blevk"
  }
}



#--------------- Task #6 ✔------------------------#

resource "aws_route53_record" "blevk_wordpress_route53_record" {
  zone_id = var.zone_id
  name    = "bwordpress.support-coe.com"
  type    = "A"

  alias {
    name                   = aws_lb.blevk_wordpress_alb.dns_name
    zone_id                = aws_lb.blevk_wordpress_alb.zone_id
    evaluate_target_health = true
  }
}

#--------------- Variables ------------------------#

variable "vpc_id" {
    type = string
    default = "some vpc"
}

variable "gw_id" {
    type = string
    default = "some igw"
}

variable "image_id" {
    type = string
    default = "ami-098f16afa9edf40be"
}

variable "zone_id" {
    type = string
    default = "someid"
}

variable "username" {
  type	= string
}

variable "password" {
  type	= string
}

variable "certificate_arn" {
  type	= string
  default = "no permissions to use aws certificate"
}

variable "LOGSTASH_1_DNS" {
  type	= string
  default = "log-1.blevk.elk"
}

variable "LOGSTASH_2_DNS" {
  type	= string
  default = "log-2.blevk.elk"
}
