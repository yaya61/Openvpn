#!/bin/bash

# Installer V2Ray
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)

# Générer une UUID
UUID=$(uuidgen)

# Créer la configuration serveur
cat > /usr/local/etc/v2ray/config.json <<EOF
{
  "inbounds": [{
    "port": 10086,
    "protocol": "vmess",
    "settings": {
      "clients": [{ "id": "$UUID", "alterId": 0 }]
    },
    "streamSettings": {
      "network": "ws",
      "security": "none",
      "wsSettings": {
        "path": "/ray"
      }
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  }]
}
EOF

# Configurer le reverse proxy avec TLS
apt install nginx -y
cat > /etc/nginx/conf.d/v2ray.conf <<EOF
server {
    listen 443 ssl;
    server_name your-domain.com;

    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

    location /ray {
        proxy_pass http://127.0.0.1:10086;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }
}
EOF

# Obtenir un certificat SSL
snap install --classic certbot
certbot --nginx -d your-domain.com

# Redémarrer les services
systemctl restart v2ray nginx
systemctl enable v2ray nginx

# Configuration du firewall
ufw allow 443/tcp
ufw reload

# Générer QR Code pour mobile
echo "vmess://$(echo -n '{"v":"2","ps":"MyV2Ray","add":"your-domain.com","port":"443","id":"'$UUID'","aid":"0","scy":"none","net":"ws","type":"none","host":"your-domain.com","path":"/ray","tls":"tls"}' | base64 -w 0)" | qrencode -o /root/client-config.png

echo "Scannez le QR code dans /root/client-config.png avec votre application mobile"
