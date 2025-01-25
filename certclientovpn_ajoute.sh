cd ~/easy-rsa
read -p clientname:
./easyrsa gen-req echo ${clientname} nopass
./easy-rsa sign-req client ${clientname}
# Créez manuellement un nouveau fichier .ovpn avec les nouveaux certificats

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
