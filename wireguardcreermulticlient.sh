#!/bin/bash

# Variables
SERVER_IP=$(curl -s ifconfig.me)  # Adresse IP publique du serveur
SERVER_PORT=51820
SERVER_NETWORK="10.0.0.1/24"
INTERFACE="wg0"
CONFIG_FILE="/etc/wireguard/$INTERFACE.conf"
CLIENTS_DIR="/etc/wireguard/clients"
DNS="8.8.8.8"

# Fonction pour afficher les messages
log() {
  echo -e "\n[+] $1"
}

# Vérifier si l'utilisateur est root
if [ "$EUID" -ne 0 ]; then
  echo "Veuillez exécuter ce script en tant que root."
  exit 1
fi

# Créer le répertoire des clients
mkdir -p $CLIENTS_DIR

# Demander le nombre de clients à créer
read -p "Combien de clients souhaitez-vous créer ? " NUM_CLIENTS

# Boucle pour créer les clients
for ((i=1; i<=NUM_CLIENTS; i++)); do
  CLIENT_NAME="client$i"
  CLIENT_IP="10.0.0.$((i+1))/32"  # Adresse IP du client
  CLIENT_CONFIG_FILE="$CLIENTS_DIR/$CLIENT_NAME.conf"

  # Générer les clés pour le client
  log "Création du client $CLIENT_NAME..."
  CLIENT_PRIVATE_KEY=$(wg genkey)
  CLIENT_PUBLIC_KEY=$(echo $CLIENT_PRIVATE_KEY | wg pubkey)

  # Créer la configuration du client
  cat > $CLIENT_CONFIG_FILE <<EOF
[Interface]
Address = $CLIENT_IP
PrivateKey = $CLIENT_PRIVATE_KEY
DNS = $DNS
MTU = 1420

[Peer]
PublicKey = $(cat /etc/wireguard/publickey)
Endpoint = $SERVER_IP:$SERVER_PORT
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

  # Ajouter le client au serveur
  log "Ajout du client $CLIENT_NAME au serveur..."
  cat >> $CONFIG_FILE <<EOF

[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
AllowedIPs = $CLIENT_IP
EOF

  # Afficher les informations du client
  echo "----------------------------------------"
  echo "Client $CLIENT_NAME créé avec succès !"
  echo "Fichier de configuration : $CLIENT_CONFIG_FILE"
  echo "Adresse IP du client : $CLIENT_IP"
  echo "Clé publique du client : $CLIENT_PUBLIC_KEY"
  echo "----------------------------------------"
done

# Redémarrer WireGuard pour appliquer les modifications
log "Redémarrage de WireGuard..."
systemctl restart wg-quick@$INTERFACE

log "Tous les clients ont été créés et ajoutés au serveur !"
