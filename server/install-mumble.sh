#!/bin/sh
apt-get update
apt install -y mumble-server certbot
ufw allow 64738/tcp
ufw allow 64738/udp
dpkg-reconfigure mumble-server
echo "enter mumble domain"
read -r domain
certbot certonly --webroot --agree-tos --text --non-interactive --webroot-path /var/www/html -d $domain
echo "enter mumble server password"
read -r password
cat <<EOF > /etc/mumble-server.ini
sslCert=/etc/letsencrypt/live/$domain/fullchain.pem
sslKey=/etc/letsencrypt/live/$domain/privkey.pem
database=/var/lib/mumble-server/mumble-server.sqlite
icesecretwrite=
logfile=/var/log/mumble-server/mumble-server.log
pidfile=/var/run/mumble-server/mumble-server.pid
welcometext="<br />dni's sexy mumble<br />enjoy your stay!<br />"
port=64738
serverpassword=$password
bandwidth=72000
users=20
uname=mumble-server
[Ice]
Ice.Warn.UnknownProperties=1
Ice.MessageSizeMax=65536
EOF
