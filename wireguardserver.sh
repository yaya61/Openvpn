#!/bin/bash

# Variables
SERVER_IP=$(curl -s ifconfig.me)  # Adresse IP publique du serveur
SERVER_PORT=51820
SERVER_NETWORK="10.0.0.1/24"
INTERFACE="wg0"
CONFIG_FILE="/etc/wireguard/$INTERFACE.conf"

# Fonction pour afficher les messages
log() {
  echo -e "\n[+] $1"
}

# Vérifier si l'utilisateur est root
if [ "$EUID" -ne 0 ]; then
  echo "Veuillez exécuter ce script en tant que root."
  exit 1
fi

# Mettre à jour le système
log "Mise à jour du système..."
apt update && apt upgrade -y

# Installer WireGuard et les dépendances
log "Installation de WireGuard..."
apt install wireguard resolvconf iptables -y

# Activer le routage IP
log "Activation du routage IP..."
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# Générer les clés pour le serveur
log "Génération des clés pour le serveur..."
mkdir -p /etc/wireguard
cd /etc/wireguard
umask 077
wg genkey | tee privatekey | wg pubkey > publickey
SERVER_PRIVATE_KEY=$(cat privatekey)
SERVER_PUBLIC_KEY=$(cat publickey)

# Créer la configuration du serveur
log "Création de la configuration du serveur..."
cat > $CONFIG_FILE <<EOF
[Interface]
Address = $SERVER_NETWORK
ListenPort = $SERVER_PORT
PrivateKey = $SERVER_PRIVATE_KEY
SaveConfig = true
PostUp = iptables -A FORWARD -i $INTERFACE -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i $INTERFACE -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
EOF

# Démarrer et activer WireGuard
log "Démarrage de WireGuard..."
systemctl enable wg-quick@$INTERFACE
systemctl start wg-quick@$INTERFACE

# Afficher les informations de configuration
log "Configuration du serveur terminée !"
echo "----------------------------------------"
echo "Adresse IP du serveur : $SERVER_IP"
echo "Port du serveur : $SERVER_PORT"
echo "Clé publique du serveur : $SERVER_PUBLIC_KEY"
echo "----------------------------------------"
echo "Utilisez la clé publique pour configurer les clients."
echo "----------------------------------------"
