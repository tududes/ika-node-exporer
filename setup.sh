#!/bin/bash

# Install dependencies
sudo apt install -y jq curl nginx-full certbot python3-certbot-nginx
curl -fsSL https://get.docker.com | bash

# this adds a rule to /etc/ufw/after.rules to have docker behind ufw
sudo wget -O /usr/local/bin/ufw-docker https://github.com/chaifeng/ufw-docker/raw/master/ufw-docker
sudo chmod +x /usr/local/bin/ufw-docker
sudo ufw-docker install
sudo ufw reload

# Quil Prometheus & Grafana Monitoring
cd $HOME
git clone https://github.com/tududes/ika-node-exporter

# prompt the user if the .env does not exist
# ask for the domain name like a user enters 'ika.nodekeeper.net'
# ask for the grafana admin password

# if the .env does not exist, create it
if [ ! -f $HOME/ika-node-exporter/.env ]; then
    read -p "Enter the domain name: " domain
    read -p "Enter the grafana admin password: " grafana_admin_password
    echo "DOMAIN=$domain" > $HOME/ika-node-exporter/.env
    echo "GRAFANA_ADMIN_PASSWORD=$grafana_admin_password" >> $HOME/ika-node-exporter/.env
fi

# source the env
source $HOME/ika-node-exporter/.env

# start the docker compose
cd $HOME/ika-node-exporter

# take down the containers and delete the volumes
docker compose down -v

# start the containers
docker compose up -d
docker compose logs -f 

# the following should be done with port 80 and certbot will convert it to 443
sudo cat <<EOL > /etc/nginx/sites-available/$DOMAIN
server {
    server_name $DOMAIN;

    location / {
        proxy_pass http://localhost:3000; # Forward requests to Grafana
        proxy_set_header Host \$host; # Pass the host header - important for virtual hosting
        proxy_set_header X-Real-IP \$remote_addr; # Pass the real client IP to Grafana
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for; # Manage the forwarded-for header
        proxy_set_header X-Forwarded-Proto \$scheme; # Manage the forwarded-proto header
    }


    listen 80;
}
server {
    if (\$host = $DOMAIN) {
        return 301 https://\$host\$request_uri;
    } # managed by Certbot


    listen 80;
    server_name $DOMAIN;
    return 404; # managed by Certbot


}
EOL

# enable the site
sudo ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/$DOMAIN

# delete the default site
sudo rm -f /etc/nginx/sites-enabled/default

# restart nginx
sudo systemctl enable nginx
nginx -s reload

# allow the port 80/443 in the firewall
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# get the cert
sudo certbot --nginx -d $DOMAIN

# restart nginx
nginx -s reload

# make sure the A record is set up in cloudflare
echo "Please make sure the A record is pointed to this server's public IP address"
curl -s https://ipinfo.io

# instruct the user to visit the dashboard and add a connection "http://prometheus:9090"
echo "Please visit the dashboard https://$DOMAIN/connections/datasources/new and add a Prometheus data source to http://prometheus:9090"


# login to Grafana and add a Prometheus data source
# USE: http://localhost:9090

# tell the user to use the following output to add a Prometheus data source
cat ./ika_dashboard.json | jq

# instruct the user to visit the dashboard and import the ika_dashboard.json output
echo "Please visit the dashboard https://$DOMAIN/dashboard/import and import the ika_dashboard.json output printed above."