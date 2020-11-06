#!/bin/bash
sudo apt-get -y update
sudo apt-get -y install default-jre
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt-get -y install apt-transport-https
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt-get -y update && sudo apt-get -y install kibana

sudo echo "server.port: 5601" >> /etc/kibana/kibana.yml
sudo echo 'server.host: "localhost"' >> /etc/kibana/kibana.yml
sudo echo "elasticsearch.hosts:" >> /etc/kibana/kibana.yml
sudo echo "  - http://${DATA_NODE_1}:9200" >> /etc/kibana/kibana.yml
sudo echo "  - http://${DATA_NODE_2}:9200" >> /etc/kibana/kibana.yml

sudo systemctl start kibana
sudo systemctl enable kibana

sudo apt-get -y install nginx apache2-utils
sudo htpasswd -c /etc/nginx/htpasswd.users kibanaadmin

sudo echo "server {" > /etc/nginx/sites-available/default
sudo echo "  listen 80;" >> /etc/nginx/sites-available/default
sudo echo "  server_name ${KIBANA_DNS};" >> /etc/nginx/sites-available/default
sudo echo "  error_log   /var/log/nginx/kibana.error.log;" >> /etc/nginx/sites-available/default
sudo echo "  access_log  /var/log/nginx/kibana.access.log;" >> /etc/nginx/sites-available/default
sudo echo "  location / {" >> /etc/nginx/sites-available/default
sudo echo "    rewrite ^/(.*) /\$1 break;" >> /etc/nginx/sites-available/default
sudo echo "    proxy_ignore_client_abort on;" >> /etc/nginx/sites-available/default
sudo echo "    proxy_pass http://localhost:8080;" >> /etc/nginx/sites-available/default
sudo echo "    proxy_set_header  X-Real-IP  \$remote_addr;" >> /etc/nginx/sites-available/default
sudo echo "    proxy_set_header  X-Forwarded-For \$proxy_add_x_forwarded_for;" >> /etc/nginx/sites-available/default
sudo echo "    proxy_set_header  Host \$http_host;" >> /etc/nginx/sites-available/default
sudo echo "    rewrite /login http://localhost:8080/oauth2/sign_in redirect;" >> /etc/nginx/sites-available/default
sudo echo "  }" >> /etc/nginx/sites-available/default
sudo echo "}" >> /etc/nginx/sites-available/default

sudo systemctl restart nginx
sudo systemclt enable nginx

sudo wget https://github.com/oauth2-proxy/oauth2-proxy/releases/download/v6.1.1/oauth2-proxy-v6.1.1.linux-amd64.tar.gz
tar -zxvf oauth2-proxy-v6.1.1.linux-amd64.tar.gz --strip-components=1 -C /bin

oauth2-proxy \
--email-domain="*" \
--upstream="http://localhost:5601/" \
--approval-prompt="auto" \
--redirect-url="http://${KIBANA_DNS}:80/oauth2/callback" \
--cookie-secret=${COOKIE_SECRET} \
--cookie-name="_oauth2_proxy" \
--cookie-secure=false \
--provider=github \
--client-id="${CLIENT_ID}" \
--client-secret="${CLIENT_SECRET}" \
--http-address="localhost:8080"


