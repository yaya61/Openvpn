sudo apt update
sudo apt install wireguard resolvconf

wg genkey | tee privatekey | wg pubkey > publickey

sudo nano /etc/wireguard/wg0.conf

[Interface]
Address = 10.0.0.1/24
SaveConfig = true
ListenPort = 51820
PrivateKey = <SERVER_PRIVATE_KEY>
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o wlp58s0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o wlp58s0 -j MASQUERADE

[Peer]
PublicKey = <CLIENT1_PUBLIC_KEY>
AllowedIPs = 10.0.0.2/32

[Peer]
PublicKey = <CLIENT2_PUBLIC_KEY>
AllowedIPs = 10.0.0.3/32


sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0



sudo nano /etc/wireguard/wg0.conf

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


sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0
