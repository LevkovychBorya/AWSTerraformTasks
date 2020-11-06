#!/bin/bash
sudo apt-get -y update
sudo apt-get -y install default-jre
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt-get -y install apt-transport-https
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt-get -y update && sudo apt-get -y install logstash
sudo touch /etc/logstash/conf.d/logstash.conf

sudo echo "input {" >> /etc/logstash/conf.d/logstash.conf
sudo echo "    beats {" >> /etc/logstash/conf.d/logstash.conf
sudo echo '        port => "5044"' >> /etc/logstash/conf.d/logstash.conf
sudo echo "    }" >> /etc/logstash/conf.d/logstash.conf
sudo echo "}" >> /etc/logstash/conf.d/logstash.conf

sudo echo "filter {" >> /etc/logstash/conf.d/logstash.conf
sudo echo '    if [fields][file_type] == "apache" {' >> /etc/logstash/conf.d/logstash.conf
sudo echo "      grok {" >> /etc/logstash/conf.d/logstash.conf
sudo echo '          match => { "message" => "%%{COMBINEDAPACHELOG}"}' >> /etc/logstash/conf.d/logstash.conf
sudo echo "      }" >> /etc/logstash/conf.d/logstash.conf
sudo echo "      geoip {" >> /etc/logstash/conf.d/logstash.conf
sudo echo '          source => "clientip"' >> /etc/logstash/conf.d/logstash.conf
sudo echo "      }" >> /etc/logstash/conf.d/logstash.conf
sudo echo "    }" >> /etc/logstash/conf.d/logstash.conf
sudo echo '    else if [fields][file_type] == "wordpress" {' >> /etc/logstash/conf.d/logstash.conf
sudo echo "      grok {" >> /etc/logstash/conf.d/logstash.conf
sudo echo '          match => [ "message", "\[%%{MONTHDAY:day}-%%{MONTH:month}-%%{YEAR:year} %%{TIME:time} %%{WORD:zone}\] PHP %%{DATA:level}\:  %%{GREEDYDATA:error}"]' >> /etc/logstash/conf.d/logstash.conf
sudo echo "      }" >> /etc/logstash/conf.d/logstash.conf
sudo echo "      mutate {" >> /etc/logstash/conf.d/logstash.conf
sudo echo '          add_field => [ "timestamp", "%%{year}-%%{month}-%%{day} %%{time}" ]' >> /etc/logstash/conf.d/logstash.conf
sudo echo '          remove_field => [ "zone", "month", "day", "time" ,"year"]' >> /etc/logstash/conf.d/logstash.conf
sudo echo "      }" >> /etc/logstash/conf.d/logstash.conf
sudo echo "      date {" >> /etc/logstash/conf.d/logstash.conf
sudo echo '          match => [ "timestamp" , "yyyy-MMM-dd HH:mm:ss" ]' >> /etc/logstash/conf.d/logstash.conf
sudo echo '          remove_field => [ "timestamp" ]' >> /etc/logstash/conf.d/logstash.conf
sudo echo "      }" >> /etc/logstash/conf.d/logstash.conf
sudo echo "    }" >> /etc/logstash/conf.d/logstash.conf
sudo echo "}" >> /etc/logstash/conf.d/logstash.conf

sudo echo "output {" >> /etc/logstash/conf.d/logstash.conf
sudo echo "    elasticsearch {" >> /etc/logstash/conf.d/logstash.conf
sudo echo '        hosts => [ "${DATA_NODE_1}", "${DATA_NODE_2}" ]' >> /etc/logstash/conf.d/logstash.conf
sudo echo "    }" >> /etc/logstash/conf.d/logstash.conf
sudo echo "}" >> /etc/logstash/conf.d/logstash.conf

sudo systemctl start logstash
sudo systemctl enable logstash