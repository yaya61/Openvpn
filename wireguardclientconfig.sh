#!/bin/bash

# Variables
SERVER_IP="<SERVER_IP>"  # Remplacez par l'IP publique du serveur
SERVER_PORT=51820
SERVER_PUBLIC_KEY="<SERVER_PUBLIC_KEY>"  # Remplacez par la clé publique du serveur
CLIENT_IP="10.0.0.2/32"
CLIENT_NAME="client1"
DNS="8.8.8.8"
Dns="1.1.1.1"
INTERFACE="wg0"
CLIENT_CONFIG_FILE="$CLIENT_NAME.conf"

# Fonction pour afficher les messages
log() {
  echo -e "\n[+] $1"
}

# Vérifier si l'utilisateur est root
if [ "$EUID" -ne 0 ]; then
  echo "Veuillez exécuter ce script en tant que root."
  exit 1
fi

# Générer les clés pour le client
log "Génération des clés pour le client..."
CLIENT_PRIVATE_KEY=$(wg genkey)
CLIENT_PUBLIC_KEY=$(echo $CLIENT_PRIVATE_KEY | wg pubkey)

# Créer la configuration du client
log "Création de la configuration du client..."
cat > $CLIENT_CONFIG_FILE <<EOF
[Interface]
Address = $CLIENT_IP
PrivateKey = $CLIENT_PRIVATE_KEY
DNS = $DNS
MTU = 1420

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $SERVER_IP:$SERVER_PORT
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

# Afficher les informations de configuration
log "Configuration du client terminée !"
echo "----------------------------------------"
echo "Fichier de configuration client : $CLIENT_CONFIG_FILE"
echo "Clé publique du client : $CLIENT_PUBLIC_KEY"
echo "----------------------------------------"
echo "Ajoutez cette clé publique au serveur WireGuard :"
echo "$CLIENT_PUBLIC_KEY"
echo "----------------------------------------"
