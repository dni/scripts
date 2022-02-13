username=$1
if [ ! -z $username ] && [ ! "$username" = "typo3" ] && [ ! "$username" = "magento2" ]; then
  echo "not a valid username: $username"
  exit 1
fi

exit

php_version=7.4
git_server="git.dnilabs.com"
templates="~/scripts/server/templates"
php_ini="/etc/php/${php_version}/apache2/php.ini"
composer_path="/usr/local/bin/composer"

# install custom repo for php
add-apt-repository ppa:ondrej/apache2
add-apt-repository ppa:ondrej/php
apt-get update

apt-get install -y php${php_version} php${php_version}-dev php${php_version}-gd php${php_version}-mysqli php${php_version}-mbstring php${php_version}-soap php${php_version}-zip php${php_version}-xml php${php_version}-bcmath php${php_version}-curl php${php_version}-intl
a2enmod php${php_version} rewrite headers expires ssl proxy proxy_http
update-alternatives --set php /usr/bin/php${php_version}

# apache blacklist
cp $templates/blacklist.conf /etc/apache2/blacklist.conf
echo 'ServerTokens Prod' >> /etc/apache2/apache2.conf
echo 'ServerSignature Off' >> /etc/apache2/apache2.conf

# install composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar ${composer_path}

# wkhtmltopdf
apt install -y wkhtmltopdf xvfb

# crontab script
cp $templates/$username/crontab.sh /srv/crontab.sh
chmod +x /srv/crontab.sh
crontab -u $username $templates/$username/crontab.txt

# landing page
rm -rf /var/www/html
git clone git@$git_server:landing.git /var/www/html
chown -R ${username}:www-data /var/www/html
