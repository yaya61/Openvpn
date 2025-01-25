cd ~/easy-rsa
read -p clientname:
./easyrsa gen-req echo ${clientname} nopass
./easy-rsa sign-req client ${clientname}
# Créez manuellement un nouveau fichier .ovpn avec les nouveaux certificats
