#!/bin/sh
apt install -y inspircd certbot openssl
ufw allow 6667/tcp
ufw allow 6697/tcp

echo "enter domain for irc server"
read -r domain

certbot certonly --webroot --agree-tos --text --non-interactive --webroot-path /var/www/html -d $domain
certs=/etc/letsencrypt/live/$domain
certfile=/etc/inspircd/fullchain.pem
keyfile=/etc/inspircd/privkey.pem
dh2048=/etc/ssl/certs/dh2048.pem
openssl dhparam -out $dh2048 2048

cp $certs/privkey.pem $keyfile
cp $certs/fullchain.pem $certfile
cp /etc/ssl/certs/dh2048.pem $dh2048
chown -R irc:irc /etc/inspircd

echo "enter server name"
read -r servername
echo "enter channel name"
read -r channelname
echo "enter username for admin"
read -r adminuser


cat <<EOF > /etc/inspircd/inspircd.motd
welcome to $servername, join $channelname
EOF

cat <<EOF > /etc/inspircd/inspircd.rules
be nice ! :)
EOF

# <power diepass="$diepass" restartpass="$restartpass" pause="2">
# <oper name="$user" password="$password" host="@localhost" type="NetAdmin">
cat << EOF > /etc/inspircd/inspircd.conf
<server name="$domain" description="$name" id="66F" network="$servername">
<admin name="$adminuser" nick="$adminuser" email="$adminemail">
<bind address="" port="6667" type="clients">
<bind address="" port="6697" ssl="openssl" type="clients">
<module name="m_sslmodes.so">
<openssl certfile="$certfile" keyfile="$keyfile" dhfile="$dh2048">
<connect allow="*" timeout="60" flood="20" threshold="1" pingfreq="120" sendq="262144" recvq="8192" localmax="3" globalmax="3">
<class name="Shutdown" commands="DIE RESTART REHASH LOADMODULE UNLOADMODULE RELOAD">
<class name="ServerLink" commands="CONNECT SQUIT RCONNECT MKPASSWD MKSHA256">
<class name="BanControl" commands="KILL GLINE KLINE ZLINE QLINE ELINE">
<class name="OperChat" commands="WALLOPS GLOBOPS SETIDLE SPYLIST SPYNAMES">
<class name="HostCloak" commands="SETHOST SETIDENT SETNAME CHGHOST CHGIDENT">
<type name="NetAdmin" classes="OperChat BanControl HostCloak Shutdown ServerLink" host="netadmin.omega.org.za">
<type name="GlobalOp" classes="OperChat BanControl HostCloak ServerLink" host="ircop.omega.org.za">
<type name="Helper" classes="HostCloak" host="helper.omega.org.za">
<files motd="/etc/inspircd/inspircd.motd" rules="/etc/inspircd/inspircd.rules">
<channels users="20" opers="60">
<dns server="8.8.8.8" timeout="5">
<pid file="/run/inspircd/inspircd.pid">
<options prefixquit="Quit: " noservices="no" qaprefixes="no" deprotectself="no" deprotectothers="no" flatlinks="no"
         hideulines="no" syntaxhints="no" cyclehosts="yes" ircumsgprefix="no" announcets="yes" disablehmac="no"
         hostintopic="yes" quietbursts="yes" pingwarning="15" allowhalfop="yes" exemptchanops="">
<security hidewhois="" userstats="Pu" customversion="" hidesplits="no" hidebans="no" operspywhois="no" hidemodes="eI" maxtargets="20">
<performance nouserdns="no" maxwho="128" softlimit="1024" somaxconn="128" netbuffersize="10240">
<log method="file" type="* -USERINPUT -USEROUTPUT" level="default" target="/var/log/inspircd.log">
<whowas groupsize="10" maxgroups="100000" maxkeep="3d">
<timesync enable="no" master="no">
<badnick nick="ChanServ" reason="Reserved For Services">
<badnick nick="NickServ" reason="Reserved For Services">
<badnick nick="OperServ" reason="Reserved For Services">
<badnick nick="MemoServ" reason="Reserved For Services">
EOF
service inspircd restart
