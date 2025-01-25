#!/bin/bash

# Mise à jour du système
apt-get update && apt-get upgrade -y

# Installation des dépendances
apt-get install -y openvpn easy-rsa

# Configuration d'EasyRSA
mkdir -p ~/easy-rsa
ln -s /usr/share/easy-rsa/* ~/easy-rsa/
chmod 700 ~/easy-rsa

# Initialisation du PKI
cd ~/easy-rsa
cat << EOF > vars
set_var EASYRSA_REQ_COUNTRY    "FR"
set_var EASYRSA_REQ_PROVINCE   "Paris"
set_var EASYRSA_REQ_CITY       "Paris"
set_var EASYRSA_REQ_ORG        "MyVPN"
set_var EASYRSA_REQ_EMAIL      "admin@example.com"
set_var EASYRSA_REQ_OU         "IT"
set_var EASYRSA_ALGO           "ec"
set_var EASYRSA_DIGEST         "sha512"
EOF

./easyrsa init-pki
./easyrsa build-ca nopass

# Génération des certificats
./easyrsa gen-req server nopass
./easyrsa sign-req server server

./easyrsa gen-dh

openvpn --genkey secret pki/ta.key

./easyrsa gen-req client1 nopass
./easyrsa sign-req client client1

# Création du dossier de configuration OpenVPN
mkdir -p /etc/openvpn/server
cp pki/ca.crt /etc/openvpn/server/
cp pki/issued/server.crt /etc/openvpn/server/
cp pki/private/server.key /etc/openvpn/server/
cp pki/dh.pem /etc/openvpn/server/
cp pki/ta.key /etc/openvpn/server/

# Configuration du serveur OpenVPN
cat << EOF > /etc/openvpn/server/server.conf
port 1194
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
server 10.8.0.0 255.255.255.0
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
keepalive 10 120
tls-auth ta.key 0
cipher AES-256-GCM
auth SHA512
user nobody
group nogroup
persist-key
persist-tun
status openvpn-status.log
verb 3
explicit-exit-notify 1
EOF

# Configuration du client
mkdir -p ~/client-config
cat << EOF > ~/client-config/client.ovpn
client
dev tun
proto udp
remote $(curl -4 ifconfig.co) 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-GCM
auth SHA512
verb 3

<ca>
$(cat pki/ca.crt)
</ca>

<cert>
$(cat pki/issued/client1.crt)
</cert>

<key>
$(cat pki/private/client1.key)
</key>

<tls-auth>
$(cat pki/ta.key)
</tls-auth>
EOF

# Activation du forwarding IP
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# Configuration du firewall
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
apt-get install -y iptables-persistent

# Démarrage du service
systemctl enable --now openvpn-server@server.service

echo "Installation terminée!"
echo "Fichier client disponible dans: ~/client-config/client.ovpn"
