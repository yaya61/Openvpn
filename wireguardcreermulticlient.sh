#!/bin/bash

SERVER_PUBLIC_KEY=$(cat /etc/wireguard/publickey)
SERVER_IP="<SERVER_IP>"

for i in {2..10}; do
  CLIENT_PRIVATE_KEY=$(wg genkey)
  CLIENT_PUBLIC_KEY=$(echo $CLIENT_PRIVATE_KEY | wg pubkey)
  CLIENT_IP="10.0.0.$i/32"

  echo "[Interface]
Address = $CLIENT_IP
PrivateKey = $CLIENT_PRIVATE_KEY
DNS = 8.8.8.8

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $SERVER_IP:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25" > /etc/wireguard/client$i.conf

  qrencode -t ansiutf8 < /etc/wireguard/client$i.conf

  echo "[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
AllowedIPs = $CLIENT_IP" >> /etc/wireguard/wg0.conf
done

sudo systemctl restart wg-quick@wg0
