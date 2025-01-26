#!/bin/bash

# Vérification des privilèges root
if [ "$EUID" -ne 0 ]; then
  echo "Veuillez exécuter en root/sudo"
  exit 1
fi

# Mise à jour et installation des paquets
apt-get update
apt-get install -y openvpn easy-rsa

# Configuration d'Easy-RSA
cp -r /usr/share/easy-rsa /etc/openvpn/
cd /etc/openvpn/easy-rsa

# Initialisation PKI
./easyrsa init-pki
echo "Configurer le serveur VPN:"
./easyrsa build-ca nopass
./easyrsa gen-req server nopass
./easyrsa sign-req server server
./easyrsa gen-dh
openvpn --genkey secret pki/ta.key

# Copie des certificats
cp pki/ca.crt pki/private/server.key pki/issued/server.crt pki/dh.pem pki/ta.key /etc/openvpn/server/

# Configuration du serveur
cat > /etc/openvpn/server/server.conf <<EOF
port 1194
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
tls-auth ta.key 0
server 10.8.0.0 255.255.255.0
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 1.1.1.1"
push "dhcp-option DNS 1.0.0.1"
keepalive 10 120
cipher AES-256-CBC
auth SHA256
user nobody
group nogroup
persist-key
persist-tun
status openvpn-status.log
verb 3
client-to-client
EOF

# Activation du routage IP
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# Configuration iptables
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o $(ip route | grep default | awk '{print $5}') -j MASQUERADE
iptables-save > /etc/iptables/rules.v4

# Démarrage du service
systemctl enable openvpn-server@server
systemctl start openvpn-server@server

echo "Serveur OpenVPN configuré avec succès!"
echo "Adresse VPN: 10.8.0.1"
