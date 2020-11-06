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

data "aws_ami" "ubuntu_20" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

data "template_file" "elastic_master_tmp" {
  template = file("templates/elasticsearch.tpl")
  vars = {
  CLUSTER_NAME = var.cluster_name
  NODE_NAME = var.master_node_name
  NODE_MASTER = "true"
  NODE_DATA = "false"
  NETWORK_HOST = var.master_DNS
  NETWORK_HOST_2 = var.data_1_DNS
  NETWORK_HOST_3 = var.data_2_DNS
  MASTER_NAME = var.master_node_name
 }
}

data "template_file" "elastic_data_1_tmp" {
  template = file("templates/elasticsearch.tpl")
  vars = {
  CLUSTER_NAME = var.cluster_name
  NODE_NAME = var.data_1_node_name
  NODE_MASTER = "false"
  NODE_DATA = "true"
  NETWORK_HOST = var.data_1_DNS
  NETWORK_HOST_2 = var.master_DNS
  NETWORK_HOST_3 = var.data_2_DNS
  MASTER_NAME = var.master_node_name
 }
}

data "template_file" "elastic_data_2_tmp" {
  template = file("templates/elasticsearch.tpl")
  vars = {
  CLUSTER_NAME = var.cluster_name
  NODE_NAME = var.data_2_node_name
  NODE_MASTER = "false"
  NODE_DATA = "true"
  NETWORK_HOST = var.data_2_DNS
  NETWORK_HOST_2 = var.master_DNS
  NETWORK_HOST_3 = var.data_1_DNS
  MASTER_NAME = var.master_node_name
 }
}

data "template_file" "logstash_tmp" {
  template = file("templates/logstash.tpl")
  vars = {
  DATA_NODE_1 = var.data_1_DNS
  DATA_NODE_2 = var.data_2_DNS
 }
}

data "template_file" "kibana_tmp" {
  template = file("templates/kibana.tpl")
  vars = {
  DATA_NODE_1 = var.data_1_DNS
  DATA_NODE_2 = var.data_2_DNS
  KIBANA_DNS = var.kibana_DNS
  COOKIE_SECRET = var.cookie_secret
  CLIENT_ID = var.client_id
  CLIENT_SECRET = var.client_secret
 }
}

data "template_file" "apache_tmp" {
  template = file("templates/apache.tpl")
  vars = {
  LOGSTASH_1_DNS = var.logstash_1_DNS
  LOGSTASH_2_DNS = var.logstash_2_DNS
 }
}

/* data "aws_secretsmanager_secret" "secrets" {
  arn = "arn:aws:secretsmanager:us-east-1:004829846714:secret:blelk-github-oauth-secret-giyKGD"
} */

/* data "aws_secretsmanager_secret_version" "github_OAuth" {
  # Fill in the name you gave to your secret
  secret_id = data.aws_secretsmanager_secret.secrets.id
} */