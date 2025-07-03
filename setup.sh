#!/bin/bash

# Install dependencies
sudo apt install -y jq curl nginx-full certbot python3-certbot-nginx

# Install Docker
if [ ! -f /usr/bin/docker ]; then
    curl -fsSL https://get.docker.com | bash
fi

# Install ufw-docker
if [ ! -f /usr/local/bin/ufw-docker ]; then
    sudo wget -O /usr/local/bin/ufw-docker https://github.com/chaifeng/ufw-docker/raw/master/ufw-docker
    sudo chmod +x /usr/local/bin/ufw-docker
    # this adds a rule to /etc/ufw/after.rules to have docker behind ufw
    sudo wget -O /usr/local/bin/ufw-docker https://github.com/chaifeng/ufw-docker/raw/master/ufw-docker
    sudo chmod +x /usr/local/bin/ufw-docker
    sudo ufw-docker install
    sudo ufw reload
fi

# Quil Prometheus & Grafana Monitoring
cd $HOME
git clone https://github.com/tududes/ika-node-exporter

# prompt the user if the .env does not exist
# ask for the domain name like a user enters 'ika.nodekeeper.net'
# ask for the grafana admin password

# if the .env does not exist, create it
if [ ! -f $HOME/ika-node-exporter/.env ]; then
    read -p "Enter the domain name: " domain
    echo "DOMAIN=$domain" > $HOME/ika-node-exporter/.env
    read -p "Enter the grafana admin password: " grafana_admin_password
    echo "GRAFANA_ADMIN_PASSWORD=$grafana_admin_password" >> $HOME/ika-node-exporter/.env
    # ask for the Sui metrics target
    read -p "Enter the Sui metrics target (e.g. 172.17.0.1:9284 - do NOT include /metrics): " sui_metrics_target
    echo "SUI_METRICS_TARGET=$sui_metrics_target" >> $HOME/ika-node-exporter/.env
    # ask for the Ika metrics target
    read -p "Enter the Ika metrics target (e.g. 172.17.0.1:9184 - do NOT include /metrics): " ika_metrics_target
    echo "IKA_METRICS_TARGET=$ika_metrics_target" >> $HOME/ika-node-exporter/.env
    # ask for the validator authority name
    read -p "Enter your Validator Authority name (e.g. MyValidator): " vn_authority
    echo "VN_AUTHORITY=$vn_authority" >> $HOME/ika-node-exporter/.env
fi

# source the env
source $HOME/ika-node-exporter/.env

# Generate prometheus.yml from original
cd $HOME/ika-node-exporter

# Create backup of original prometheus.yml if it doesn't exist
if [ ! -f prometheus.yml.original ]; then
    cp prometheus.yml prometheus.yml.original
fi

# Generate prometheus.yml with substituted values from original
echo "Generating prometheus.yml with actual metrics targets..."
sed "s|\${IKA_METRICS_TARGET}|$IKA_METRICS_TARGET|g; s|\${SUI_METRICS_TARGET}|$SUI_METRICS_TARGET|g" prometheus.yml.original > prometheus.yml

# Replace VN_AUTHORITY in Grafana dashboard JSON
if [ ! -z "$VN_AUTHORITY" ]; then
    echo "Updating Grafana dashboard with authority: $VN_AUTHORITY"
    # Create backup of original dashboard
    if [ ! -f Grafana-TrustedPoint-Ika-Sui.json.original ]; then
        cp Grafana-TrustedPoint-Ika-Sui.json Grafana-TrustedPoint-Ika-Sui.json.original
    fi
    # Replace VN_AUTHORITY with actual validator name
    sed -i "s/VN_AUTHORITY/$VN_AUTHORITY/g" Grafana-TrustedPoint-Ika-Sui.json
fi

# start the docker compose
cd $HOME/ika-node-exporter

# take down the containers and delete the volumes
DOCKER_VOUME_FRESH="false"
DOCKER_VOLUME_EXISTS=$(docker volume inspect ika-node-exporter_grafana-data > /dev/null 2>&1 && echo "true" || echo "false")
if [ "$DOCKER_VOLUME_EXISTS" == "true" ]; then
    read -p "Do you want to start fresh? (y/n): " start_fresh
    if [ "$start_fresh" == "y" ]; then
        DOCKER_VOUME_FRESH="true"
    fi
fi

if [ "$DOCKER_VOUME_FRESH" == "true" ]; then
    docker compose down --volumes
else
    docker compose down
fi

# start the containers
docker compose up -d
docker compose logs --tail 100

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
public_ip=$(curl -s https://ipinfo.io/ip)
echo "Please make sure the A record is pointed to this server's public IP address: $public_ip"

# there should be a prometheus data source already created
# THIS: http://localhost:9090

# instruct the user to visit the dashboard and import the ika_dashboard.json output
echo "Prometheus & Grafana ready to go! Visit the dashboard https://$DOMAIN and login with your admin credentials."