#!/bin/sh

echo "##### apache2.sh START #####"

apt-get install -y apache2 libapache2-mod-fcid > /dev/null
a2enmod rewrite headers expires ssl proxy proxy_http proxy_fcgi setenvif
a2enconf php8.2-fpm

# seo
echo 'ServerTokens Prod' >> /etc/apache2/apache2.conf
echo 'ServerSignature Off' >> /etc/apache2/apache2.conf

# blacklist
cp /root/scripts/server/templates/blacklist.conf /etc/apache2/blacklist.conf

# landing page
rm -rf /var/www/html
git clone https://github.com:dni/landing.git /var/www/html
chown -R www-data:www-data /var/www/html

echo "##### apache2.sh END #####"
