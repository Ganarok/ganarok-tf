#!/bin/bash

cd /home
sudo apt-get update
sudo apt install -y docker.io
sudo groupadd docker
sudo gpasswd -a ubuntu docker
sudo docker plugin install grafana/loki-docker-driver:latest --alias loki --grant-all-permissions
touch Caddyfile
echo -e "https://${var.domain_name},\nhttps://www.${var.domain_name} {\n \t reverse_proxy localhost:${var.ec2_ports[0]}\n }\n" >> Caddyfile
sudo docker run -d -p 80:80 -p 443:443 -p 443:443/udp -v $PWD/Caddyfile:/etc/caddy/Caddyfile -v caddy_data:/data -v caddy_config:/config --name caddy caddy
