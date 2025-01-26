#!/bin/bash

# Vérification des privilèges root
if [ "$EUID" -ne 0 ]; then
  echo "Veuillez exécuter en root/sudo"
  exit 1
fi

# Vérification du nom client
if [ -z "$1" ]; then
  echo "Usage: $0 <nom-client>"
  exit 1
fi

CLIENT_NAME=$1
SERVER_IP=$(curl -s ifconfig.me)

cd /etc/openvpn/easy-rsa

# Génération certificat client
./easyrsa gen-req ${CLIENT_NAME} nopass
./easyrsa sign-req client ${CLIENT_NAME}

# Création du dossier client
mkdir -p ~/openvpn-clients/${CLIENT_NAME}
cp pki/ca.crt pki/ta.key pki/issued/${CLIENT_NAME}.crt pki/private/${CLIENT_NAME}.key ~/openvpn-clients/${CLIENT_NAME}

# Génération configuration client
cat > ~/openvpn-clients/${CLIENT_NAME}/${CLIENT_NAME}.ovpn <<EOF
client
dev tun
proto udp
remote ${SERVER_IP} 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
auth SHA256
verb 3

<ca>
$(cat /etc/openvpn/server/ca.crt)
</ca>

<cert>
$(cat ~/openvpn-clients/${CLIENT_NAME}/${CLIENT_NAME}.crt)
</cert>

<key>
$(cat ~/openvpn-clients/${CLIENT_NAME}/${CLIENT_NAME}.key)
</key>

<tls-auth>
$(cat /etc/openvpn/server/ta.key)
</tls-auth>
EOF

echo "Configuration client générée: ~/openvpn-clients/${CLIENT_NAME}/${CLIENT_NAME}.ovpn"
