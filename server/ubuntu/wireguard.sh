#!/bin/sh
echo "endpoint with port (61951):"
read -r endpoint

apt-get update
apt-get upgrade
apt install -y wireguard
ufw allow 61951/udp
echo "Uncomment line. net.ipv4.ip_forward=1, press key to continue"
read
vim /etc/sysctl.conf
sysctl -p

wg_add_key() {
  echo "$1: private and public key pairs creation"
  wg genkey | tee /etc/wireguard/$1_private.key | wg pubkey | tee /etc/wireguard/$1_public.key
  chmod 600 /etc/wireguard/$1_private.key
}

wg_add_key server

server_private=$(cat /etc/wireguard/server_private.key)
server_public=$(cat /etc/wireguard/server_public.key)

cat <<EOF > /etc/wireguard/wg0.conf
[Interface]
PrivateKey = $server_private
Address = 10.5.5.1/24
ListenPort = 61951
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
EOF

add_client() {
  name=$1
  wg_add_key $name
  key=$(cat /etc/wireguard/$name\_private.key)
  pub=$(cat /etc/wireguard/$name\_public.key)
  i=$(echo $name | grep -o ".$")
cat <<EOF > /etc/wireguard/$name.conf
[Interface]
PrivateKey = $key
Address = 10.5.5.$i/24
DNS = 8.8.8.8
[Peer]
PublicKey = $server_public
AllowedIPs = 0.0.0.0/0
Endpoint = $endpoint
PersistentKeepalive = 25
EOF
cat <<EOF >> /etc/wireguard/wg0.conf
[Peer]
PublicKey = $pub
AllowedIPs = 10.5.5.$i/32
EOF
}

add_client client2
add_client client3
add_client client4
add_client client5
add_client client6
add_client client7
add_client client8

tar -czf clients.tar.gz /etc/wireguard/client*
echo "written ./clients.tar.gz"

systemctl start wg-quick@wg0
systemctl enable wg-quick@wg0
