#!/bin/sh

ssid=$1
psk=$2

apt-get update > /dev/null
apt-get upgrade -y > /dev/null
apt-get install -y iptables dnsmasq tmux

cat <<EOF >> /etc/wpa_supplicant/wpa_supplicant.conf
network={
    ssid="$ssid"
    psk="$psk"
}
EOF

cat <<EOF > /etc/dhcpcd.conf
interface wlan0
static ip_address=192.168.1.169
static routers=192.168.1.122
static domain_name_servers=192.168.1.122

interface eth0
static ip_address=192.168.169.1
static routers=192.168.169.0
EOF

cat <<EOF > /etc/dnsmasq.conf
interface=eth0
listen-address=192.168.169.1
bind-dynamic
server=8.8.8.8
domain-needed
bogus-priv
dhcp-range=192.168.169.42,192.168.169.69,12h
EOF

echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

service dhcpcd restart
service dnsmasq restart

iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
iptables -A FORWARD -i wlan0 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o wlan0 -j ACCEPT
iptables-save > /etc/iptables.ipv4.nat


# delete last line of rc.local
sed -i '$d' /etc/rc.local
cat <<EOF >> /etc/rc.local
iptables-restore < /etc/iptables.ipv4.nat
exit 0
EOF

reboot
