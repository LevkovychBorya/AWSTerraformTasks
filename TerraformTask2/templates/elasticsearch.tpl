#!/bin/bash
sudo apt-get -y update
sudo apt-get -y install default-jre
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt-get -y install apt-transport-https
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt-get -y update && sudo apt-get -y install elasticsearch
sudo chmod 766 /etc/elasticsearch/elasticsearch.yml

sudo echo "cluster.name: ${CLUSTER_NAME}" >> /etc/elasticsearch/elasticsearch.yml
sudo echo "node.name: ${NODE_NAME}" >> /etc/elasticsearch/elasticsearch.yml
sudo echo "node.master: ${NODE_MASTER}" >> /etc/elasticsearch/elasticsearch.yml
sudo echo "node.data: ${NODE_DATA}" >> /etc/elasticsearch/elasticsearch.yml
sudo echo "network.host: ${NETWORK_HOST}" >> /etc/elasticsearch/elasticsearch.yml
sudo echo "http.port: 9200" >> /etc/elasticsearch/elasticsearch.yml
sudo echo "discovery.seed_hosts:" >> /etc/elasticsearch/elasticsearch.yml
sudo echo "        - ${NETWORK_HOST}" >> /etc/elasticsearch/elasticsearch.yml
sudo echo "        - ${NETWORK_HOST_2}" >> /etc/elasticsearch/elasticsearch.yml
sudo echo "        - ${NETWORK_HOST_3}" >> /etc/elasticsearch/elasticsearch.yml 
sudo echo "cluster.initial_master_nodes:" >> /etc/elasticsearch/elasticsearch.yml
sudo echo "        - ${MASTER_NAME}" >> /etc/elasticsearch/elasticsearch.yml

sudo systemctl start elasticsearch
sudo systemctl enable elasticsearch