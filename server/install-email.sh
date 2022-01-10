#!/bin/sh
# mostly from https://github.com/LukeSmithxyz/emailwiz/blob/master/emailwiz.sh

# validate inputs
echo "insert domain root (domain.com):"
read -r domain

echo "make sure dns of $domain and mail.$domain are pointing to this server and a reverse dns is configured for your IP"
echo "on installation of Postfix, select "Internet Site" and put in TLD (without mail. before it)."
echo "press enter to continue"
read -r ready

#echo "clean previous attempts"
#rm -rf /etc/dovecot /var/lib/dovecot

echo "installing programs..."
apt install apache2 certbot postfix dovecot-imapd dovecot-sieve opendkim spamassassin spamc

echo "get certificates"
certbot certonly --webroot --agree-tos --text --non-interactive --webroot-path /var/www/html -d $domain
certbot certonly --webroot --agree-tos --text --non-interactive --webroot-path /var/www/html -d mail.$domain


# Check if OpenDKIM is installed and install it if not.
which opendkim-genkey >/dev/null 2>&1 || apt install opendkim-tools
domain="$(cat /etc/mailname)"
subdom=${MAIL_SUBDOM:-mail}
maildomain="$subdom.$domain"
certdir="/etc/letsencrypt/live/$maildomain"

echo "Configuring Postfix's main.cf..."

# https://github.com/LukeSmithxyz/emailwiz/issues/178
postfix -e "header_checks = regexp:/etc/postfix/header_checks"
echo "/^Received:.*/     IGNORE
/^X-Originating-IP:/    IGNORE" >> /etc/postfix/header_checks

# Change the cert/key files to the default locations of the Let's Encrypt cert/key
postconf -e "smtpd_tls_key_file=$certdir/privkey.pem"
postconf -e "smtpd_tls_cert_file=$certdir/fullchain.pem"
postconf -e "smtp_tls_CAfile=$certdir/cert.pem"

# Enable, but do not require TLS. Requiring it with other server would cause
# mail delivery problems and requiring it locally would cause many other
# issues.
postconf -e "smtpd_tls_security_level = may"
postconf -e "smtp_tls_security_level = may"

# TLS required for authentication.
postconf -e "smtpd_tls_auth_only = yes"

# Exclude obsolete, insecure and obsolete encryption protocols.
postconf -e "smtpd_tls_mandatory_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1"
postconf -e "smtp_tls_mandatory_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1"
postconf -e "smtpd_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1"
postconf -e "smtp_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1"

# Exclude suboptimal ciphers.
postconf -e "tls_preempt_cipherlist = yes"
postconf -e "smtpd_tls_exclude_ciphers = aNULL, LOW, EXP, MEDIUM, ADH, AECDH, MD5, DSS, ECDSA, CAMELLIA128, 3DES, CAMELLIA256, RSA+AES, eNULL"

# Here we tell Postfix to look to Dovecot for authenticating users/passwords.
# Dovecot will be putting an authentication socket in /var/spool/postfix/private/auth
postconf -e "smtpd_sasl_auth_enable = yes"
postconf -e "smtpd_sasl_type = dovecot"
postconf -e "smtpd_sasl_path = private/auth"

# Sender and recipient restrictions
postconf -e "smtpd_recipient_restrictions = permit_sasl_authenticated, permit_mynetworks, reject_unauth_destination"

# NOTE: the trailing slash here, or for any directory name in the home_mailbox
# command, is necessary as it distinguishes a maildir (which is the actual
# directories that what we want) from a spoolfile (which is what old unix
# boomers want and no one else).
postconf -e "home_mailbox = Mail/Inbox/"

# master.cf
echo "Configuring Postfix's master.cf..."

sed -i "/^\s*-o/d;/^\s*submission/d;/^\s*smtp/d" /etc/postfix/master.cf

echo "smtp unix - - n - - smtp
smtp inet n - y - - smtpd
  -o content_filter=spamassassin
submission inet n       -       y       -       -       smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=encrypt
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_tls_auth_only=yes
smtps     inet  n       -       y       -       -       smtpd
  -o syslog_name=postfix/smtps
  -o smtpd_tls_wrappermode=yes
  -o smtpd_sasl_auth_enable=yes
spamassassin unix -     n       n       -       -       pipe
  user=debian-spamd argv=/usr/bin/spamc -f -e /usr/sbin/sendmail -oi -f \${sender} \${recipient}" >> /etc/postfix/master.cf

mv /etc/dovecot/dovecot.conf /etc/dovecot/dovecot.backup.conf

echo "Creating Dovecot config..."
echo "# Dovecot config
# Note that in the dovecot conf, you can use:
# %u for username
# %n for the name in name@domain.tld
# %d for the domain
# %h the user's home directory

# If you're not a brainlet, SSL must be set to required.
ssl = required
ssl_cert = <$certdir/fullchain.pem
ssl_key = <$certdir/privkey.pem
ssl_min_protocol = TLSv1.2
ssl_cipher_list = EECDH+ECDSA+AESGCM:EECDH+aRSA+AESGCM:EECDH+ECDSA+SHA256:EECDH+aRSA+SHA256:EECDH+ECDSA+SHA384:EECDH+ECDSA+SHA256:EECDH+aRSA+SHA384:EDH+aRSA+AESGCM:EDH+aRSA+SHA256:EDH+aRSA:EECDH:!aNULL:!eNULL:!MEDIUM:!LOW:!3DES:!MD5:!EXP:!PSK:!SRP:!DSS:!RC4:!SEED
ssl_prefer_server_ciphers = yes
ssl_dh = </usr/share/dovecot/dh.pem
# Plaintext login. This is safe and easy thanks to SSL.
auth_mechanisms = plain login
auth_username_format = %n

protocols = \$protocols imap

# Search for valid users in /etc/passwd
userdb {
	driver = passwd
}
#Fallback: Use plain old PAM to find user passwords
passdb {
	driver = pam
}

# Our mail for each user will be in ~/Mail, and the inbox will be ~/Mail/Inbox
# The LAYOUT option is also important because otherwise, the boxes will be \`.Sent\` instead of \`Sent\`.
mail_location = maildir:~/Mail:INBOX=~/Mail/Inbox:LAYOUT=fs
namespace inbox {
	inbox = yes
	mailbox Drafts {
	special_use = \\Drafts
	auto = subscribe
}
	mailbox Junk {
	special_use = \\Junk
	auto = subscribe
	autoexpunge = 30d
}
	mailbox Sent {
	special_use = \\Sent
	auto = subscribe
}
	mailbox Trash {
	special_use = \\Trash
}
	mailbox Archive {
	special_use = \\Archive
}
}

# Here we let Postfix use Dovecot's authetication system.

service auth {
  unix_listener /var/spool/postfix/private/auth {
	mode = 0660
	user = postfix
	group = postfix
}
}

protocol lda {
  mail_plugins = \$mail_plugins sieve
}

protocol lmtp {
  mail_plugins = \$mail_plugins sieve
}

plugin {
	sieve = ~/.dovecot.sieve
	sieve_default = /var/lib/dovecot/sieve/default.sieve
	#sieve_global_path = /var/lib/dovecot/sieve/default.sieve
	sieve_dir = ~/.sieve
	sieve_global_dir = /var/lib/dovecot/sieve/
}
" > /etc/dovecot/dovecot.conf

# If using an old version of Dovecot, remove the ssl_dl line.
case "$(dovecot --version)" in
	1|2.1*|2.2*) sed -i "/^ssl_dh/d" /etc/dovecot/dovecot.conf ;;
esac

mkdir /var/lib/dovecot/sieve/

echo "require [\"fileinto\", \"mailbox\"];
if header :contains \"X-Spam-Flag\" \"YES\"
	{
		fileinto \"Junk\";
	}" > /var/lib/dovecot/sieve/default.sieve

grep -q "^vmail:" /etc/passwd || useradd vmail
chown -R vmail:vmail /var/lib/dovecot
sievec /var/lib/dovecot/sieve/default.sieve

echo "Preparing user authentication..."
grep -q nullok /etc/pam.d/dovecot ||
echo "auth    required        pam_unix.so nullok
account required        pam_unix.so" >> /etc/pam.d/dovecot

# OpenDKIM

# Create an OpenDKIM key in the proper place with proper permissions.
echo "Generating OpenDKIM keys..."
mkdir -p /etc/postfix/dkim
opendkim-genkey -D /etc/postfix/dkim/ -d "$domain" -s "$subdom"
chgrp opendkim /etc/postfix/dkim/*
chmod g+r /etc/postfix/dkim/*

# Generate the OpenDKIM info:
echo "Configuring OpenDKIM..."
grep -q "$domain" /etc/postfix/dkim/keytable 2>/dev/null ||
echo "$subdom._domainkey.$domain $domain:$subdom:/etc/postfix/dkim/$subdom.private" >> /etc/postfix/dkim/keytable

grep -q "$domain" /etc/postfix/dkim/signingtable 2>/dev/null ||
echo "*@$domain $subdom._domainkey.$domain" >> /etc/postfix/dkim/signingtable

grep -q "127.0.0.1" /etc/postfix/dkim/trustedhosts 2>/dev/null ||
	echo "127.0.0.1
10.1.0.0/16" >> /etc/postfix/dkim/trustedhosts

# ...and source it from opendkim.conf
grep -q "^KeyTable" /etc/opendkim.conf 2>/dev/null || echo "KeyTable file:/etc/postfix/dkim/keytable
SigningTable refile:/etc/postfix/dkim/signingtable
InternalHosts refile:/etc/postfix/dkim/trustedhosts" >> /etc/opendkim.conf

sed -i '/^#Canonicalization/s/simple/relaxed\/simple/' /etc/opendkim.conf
sed -i '/^#Canonicalization/s/^#//' /etc/opendkim.conf

sed -i '/Socket/s/^#*/#/' /etc/opendkim.conf
grep -q "^Socket\s*inet:12301@localhost" /etc/opendkim.conf || echo "Socket inet:12301@localhost" >> /etc/opendkim.conf

# OpenDKIM daemon settings, removing previously activated socket.
sed -i "/^SOCKET/d" /etc/default/opendkim && echo "SOCKET=\"inet:12301@localhost\"" >> /etc/default/opendkim

# Here we add to postconf the needed settings for working with OpenDKIM
echo "Configuring Postfix with OpenDKIM settings..."
postconf -e "smtpd_sasl_security_options = noanonymous, noplaintext"
postconf -e "smtpd_sasl_tls_security_options = noanonymous"
postconf -e "myhostname = $domain"
postconf -e "milter_default_action = accept"
postconf -e "milter_protocol = 6"
postconf -e "smtpd_milters = inet:localhost:12301"
postconf -e "non_smtpd_milters = inet:localhost:12301"
postconf -e "mailbox_command = /usr/lib/dovecot/deliver"

# A fix for "Opendkim won't start: can't open PID file?", as specified here: https://serverfault.com/a/847442
/lib/opendkim/opendkim.service.generate
systemctl daemon-reload

for x in spamassassin opendkim dovecot postfix; do
	printf "Restarting %s..." "$x"
	service "$x" restart && printf " ...done\\n"
done

# If ufw is used, enable the mail ports.
pgrep ufw >/dev/null && { ufw allow 993; ufw allow 465 ; ufw allow 587; ufw allow 25 ;}

pval="$(tr -d "\n" </etc/postfix/dkim/$subdom.txt | sed "s/k=rsa.* \"p=/k=rsa; p=/;s/\"\s*\"//;s/\"\s*).*//" | grep -o "p=.*")"
dkimentry="$subdom._domainkey.$domain	TXT	v=DKIM1; k=rsa; $pval"
dmarcentry="_dmarc.$domain	TXT	v=DMARC1; p=reject; rua=mailto:dmarc@$domain; fo=1"
spfentry="@	TXT	v=spf1 mx a:$maildomain -all"

useradd -m -G mail dmarc

echo "$dkimentry
$dmarcentry
$spfentry" > "$HOME/dns_emailwizard"

printf "\033[0m
Add these three records to your DNS TXT records on either your registrar's site or your DNS server:
\033[32m
$dkimentry

$dmarcentry

$spfentry

"

echo "use: useradd -m -G mail office; passwd office"
echo "to add new user and password for office@$domain"
