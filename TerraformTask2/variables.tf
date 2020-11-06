# Local DNS name resolutions

variable "local_DNS_zone_id" {
  type	= string
  default = "some id"
}
variable "master_DNS" {
  type	= string
  default = "elastic-master.blevk.elk"
}
variable "data_1_DNS" {
  type	= string
  default = "elastic-data-1.blevk.elk"
}
variable "data_2_DNS" {
  type	= string
  default = "elastic-data-2.blevk.elk"
}
variable "logstash_1_DNS" {
  type	= string
  default = "log-1.blevk.elk"
}
variable "logstash_2_DNS" {
  type	= string
  default = "log-2.blevk.elk"
}

# Public DNS zone

variable "public_DNS_zone_id" {
  type	= string
  default = "some id"
}
variable "kibana_DNS" {
  type	= string
  default = "blelk.support-coe.com"
}

# Elasticsearch cluster nodes

variable "master_node_name" {
  type	= string
  default = "blelk_master"
}
variable "data_1_node_name" {
  type	= string
  default = "blelk_data_1"
}
variable "data_2_node_name" {
  type	= string
  default = "blelk_data_2"
}
variable "cluster_name" {
  type	= string
  default = "blelk_cluster"
}

# Configuring OAuth

variable "cookie_secret" {
  type	= string

  validation {
    condition     = length(var.cookie_secret) == 16 || length(var.cookie_secret) == 24 || length(var.cookie_secret) == 32
    error_message = "Cookie_secret must be 16, 24, or 32 characters long!"
  }
}
variable "client_id" {
  type	= string
}
variable "client_secret" {
  type	= string
}
