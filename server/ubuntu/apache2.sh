#!/bin/sh
apt install -y apache2
a2enmod rewrite headers expires ssl proxy proxy_http

# seo
echo 'ServerTokens Prod' >> /etc/apache2/apache2.conf
echo 'ServerSignature Off' >> /etc/apache2/apache2.conf

# blacklist
cp $templates/blacklist.conf /etc/apache2/blacklist.conf

# landing page
rm -rf /var/www/html
git clone git@git.dnilabs.com:landing.git /var/www/html
chown -R www-data:www-data /var/www/html

