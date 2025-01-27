#!/bin/bash

[Interface]
Address = 10.0.0.2/32
PrivateKey = <CLIENT_PRIVATE_KEY>
DNS = 8.8.8.8

[Peer]
PublicKey = <SERVER_PUBLIC_KEY>
Endpoint = <SERVER_IP>:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
[Interface]
Address = 10.0.0.2/32
PrivateKey = <CLIENT_PRIVATE_KEY>
DNS = 8.8.8.8

[Peer]
PublicKey = <SERVER_PUBLIC_KEY>
Endpoint = <SERVER_IP>:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
