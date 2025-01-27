# Accepter le trafic sur l'interface WireGuard (wg0)
iptables -A INPUT -i wg0 -j ACCEPT
iptables -A FORWARD -i wg0 -j ACCEPT

# Accepter le trafic sur les interfaces physiques (eth0, eth1, etc.)
iptables -A INPUT -i eth0 -p udp --dport 51820 -j ACCEPT
iptables -A INPUT -i eth1 -p udp --dport 51820 -j ACCEPT

# Accepter le trafic sortant via l'interface WireGuard
iptables -A OUTPUT -o wg0 -j ACCEPT

# Masquer le trafic sortant vers Internet via l'interface physique
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE

# Autoriser le forwarding entre les interfaces
iptables -A FORWARD -i wg0 -o eth0 -j ACCEPT
iptables -A FORWARD -i wg0 -o eth1 -j ACCEPT
iptables -A FORWARD -i eth0 -o wg0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth1 -o wg0 -m state --state RELATED,ESTABLISHED -j ACCEPT
