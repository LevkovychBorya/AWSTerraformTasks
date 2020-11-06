#!/bin/bash
sudo apt-get -y update
sudo apt-get -y install default-jre
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt-get -y install apt-transport-https
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt-get -y update && sudo apt-get -y install filebeat

sudo echo "filebeat.inputs:" > /etc/filebeat/filebeat.yml
sudo echo "  - type: log" >> /etc/filebeat/filebeat.yml
sudo echo "    paths:" >> /etc/filebeat/filebeat.yml
sudo echo "      - /var/log/apache2/*.log" >> /etc/filebeat/filebeat.yml
sudo echo "    fields: {file_type: apache}" >> /etc/filebeat/filebeat.yml
sudo echo "output.logstash:" >> /etc/filebeat/filebeat.yml
sudo echo '  hosts: ["${LOGSTASH_1_DNS}:5044", "${LOGSTASH_2_DNS}:5044"]' >> /etc/filebeat/filebeat.yml

sudo systemctl start filebeat
sudo systemctl enable filebeat

sudo apt-get -y install apache2
sudo systemclt start apache2
sudo systemclt enable apache2

