#!/bin/bash

efs_id="${efs_id}"
DB_NAME="${DB_NAME}"
DB_USER="${DB_USER}"
DB_PASSWORD="${DB_PASSWORD}"
DB_HOST="${DB_HOST}"

# Download amazon-efs-utils and mount efs to /var/www/
#sudo yum -y update
sudo yum -y install git make rpm-build
git clone https://github.com/aws/efs-utils
cd efs-utils && sudo make rpm && sudo yum -y install ./build/amazon-efs-utils*rpm
sudo mkdir /var/www/
sudo mount -t efs -o tls $efs_id:/ /var/www

# Install apache and mysql
sudo yum -y install httpd mysql

# Install php v7.4 and packages for it
sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
sudo yum -y install https://rpms.remirepo.net/enterprise/remi-release-8.rpm
sudo dnf -y install dnf-utils
sudo dnf -y module install php:remi-7.4
sudo yum -y install php-gd php-mysqlnd

# Restart apache and enable it
sudo systemctl restart httpd.service
sudo systemctl enable httpd.service

# Change selinux from enforced to permissive mode
sudo setenforce 0

if [ ! -f /var/www/html/wp-config.php ]; then

  # Download wordpress and give apache permissions
  sudo yum -y install wget
  sudo wget -P /tmp http://wordpress.org/latest.tar.gz
  sudo tar xzvf /tmp/latest.tar.gz --strip-components=1 -C /var/www/html
  sudo chown -R apache:apache /var/www/html/

  touch /var/www/html/wp-config.php

  # Generate configuration file
  echo "<?php"                                                                        >> /var/www/html/wp-config.php
  echo "if (\$_SERVER['HTTP_X_FORWARDED_PROTO'] == 'https') \$_SERVER['HTTPS']='on';" >> /var/www/html/wp-config.php
  echo "define( 'WP_DEBUG', true );"                                                  >> /var/www/html/wp-config.php
  echo "define( 'WP_DEBUG_LOG', true );"                                              >> /var/www/html/wp-config.php
  echo "define( 'WP_DEBUG_DISPLAY', false );"                                         >> /var/www/html/wp-config.php
  echo "define( 'DB_NAME', '"$DB_NAME"' );"                                           >> /var/www/html/wp-config.php
  echo "define( 'DB_USER', '"$DB_USER"' );"                                           >> /var/www/html/wp-config.php
  echo "define( 'DB_PASSWORD', '"$DB_PASSWORD"' );"                                   >> /var/www/html/wp-config.php
  echo "define( 'DB_HOST', '"$DB_HOST"' );"                                           >> /var/www/html/wp-config.php
  echo "define( 'DB_CHARSET', 'utf8' );"                                              >> /var/www/html/wp-config.php
  echo "define( 'DB_COLLATE', '' );"                                                  >> /var/www/html/wp-config.php
  echo "define( 'AUTH_KEY',         'put your unique phrase here' );"                 >> /var/www/html/wp-config.php
  echo "define( 'SECURE_AUTH_KEY',  'put your unique phrase here' );"                 >> /var/www/html/wp-config.php
  echo "define( 'LOGGED_IN_KEY',    'put your unique phrase here' );"                 >> /var/www/html/wp-config.php
  echo "define( 'NONCE_KEY',        'put your unique phrase here' );"                 >> /var/www/html/wp-config.php
  echo "define( 'AUTH_SALT',        'put your unique phrase here' );"                 >> /var/www/html/wp-config.php
  echo "define( 'SECURE_AUTH_SALT', 'put your unique phrase here' );"                 >> /var/www/html/wp-config.php
  echo "define( 'LOGGED_IN_SALT',   'put your unique phrase here' );"                 >> /var/www/html/wp-config.php
  echo "define( 'NONCE_SALT',       'put your unique phrase here' );"                 >> /var/www/html/wp-config.php
  echo "\$table_prefix = 'wp_';"                                                      >> /var/www/html/wp-config.php
  echo "define( 'WP_DEBUG', false );"                                                 >> /var/www/html/wp-config.php
  echo "if ( ! defined( 'ABSPATH' ) ) {"                                              >> /var/www/html/wp-config.php
  echo "	define( 'ABSPATH', dirname( __FILE__ ) . '/' );"                          >> /var/www/html/wp-config.php
  echo "}"                                                                            >> /var/www/html/wp-config.php
  echo "require_once( ABSPATH . 'wp-settings.php' );"                                 >> /var/www/html/wp-config.php

  sudo chmod -R 775 /var/www/html
fi

# Install filebeat

sudo yum -y install java
sudo rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
sudo echo "[elastic-7.x]" >> /etc/yum.repos.d/elastic.repo
sudo echo "name=Elastic repository for 7.x packages" >> /etc/yum.repos.d/elastic.repo
sudo echo "baseurl=https://artifacts.elastic.co/packages/7.x/yum" >> /etc/yum.repos.d/elastic.repo
sudo echo "gpgcheck=1" >> /etc/yum.repos.d/elastic.repo
sudo echo "gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch" >> /etc/yum.repos.d/elastic.repo
sudo echo "enabled=1" >> /etc/yum.repos.d/elastic.repo
sudo echo "autorefresh=1" >> /etc/yum.repos.d/elastic.repo
sudo echo "type=rpm-md" >> /etc/yum.repos.d/elastic.repo
sudo yum -y install filebeat

sudo echo "filebeat.inputs:" > /etc/filebeat/filebeat.yml
sudo echo "  - type: log" >> /etc/filebeat/filebeat.yml
sudo echo "    enabled: true" >> /etc/filebeat/filebeat.yml
sudo echo "    paths:" >> /etc/filebeat/filebeat.yml
sudo echo "      - /var/log/httpd/*log" >> /etc/filebeat/filebeat.yml
sudo echo "    fields: {file_type: apache}" >> /etc/filebeat/filebeat.yml
sudo echo "  - type: log" >> /etc/filebeat/filebeat.yml
sudo echo "    enabled: true" >> /etc/filebeat/filebeat.yml
sudo echo "    paths:" >> /etc/filebeat/filebeat.yml
sudo echo "      - /var/www/html/wp-content/debug.log" >> /etc/filebeat/filebeat.yml
sudo echo "    fields: {file_type: wordpress}" >> /etc/filebeat/filebeat.yml
sudo echo "output.logstash:" >> /etc/filebeat/filebeat.yml
sudo echo '  hosts: ["${LOGSTASH_1_DNS}:5044", "${LOGSTASH_2_DNS}:5044"]' >> /etc/filebeat/filebeat.yml

sudo systemctl start filebeat
sudo systemctl enable filebeat
