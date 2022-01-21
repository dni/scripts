username=$1
if [ ! -z $username ] && [ ! "$username" = "typo3" ] && [ ! "$username" = "magento2" ]; then
  echo "not a valid username: $username"
  exit 1
fi

exit

git_server="git.dnilabs.com"
templates="~/scripts/server/templates"
php_version=7.4
php_ini="/etc/php/${php_version}/apache2/php.ini"
composer_path="/usr/local/bin/composer"

echo "enter username for deploy user"
read -r username
sleep 3

useradd -G www-data $username
mkdir -p /home/#{username}/.composer
cp $templates/auth.json /home/$username/.composer/auth.json

# TODO: ssh not functional atm
mkdir -p /home/$username/.ssh
cp $templates/private/gitkey /home/$username/.ssh/id_rsa
chmod 600 /home/$username/.ssh/id_rsa
echo "Host $git_server
  StrictHostKeyChecking no
  IdentityFile ~/.ssh/id_rsa" > /home/$username/.ssh/config
chmod 600 /home/$username/.ssh/config

chown -R $username /home/$username/
chown -R $username:www-data /var/www

# echo "$username ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

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

# varnish
apt-get install -y varnish
sed -i "s/Listen 80.*/Listen 8080/" /etc/apache2/ports.conf
sed -i -e "s/6081/80 -p feature=+esi_ignore_https/g" -e "s/256m/512m/g" /etc/systemd/system/multi-user.target.wants/varnish.service
sed -i -e "s/6081/80 -p feature=+esi_ignore_https/g" -e "s/256m/512m/g" /lib/systemd/system/varnish.service
systemctl daemon-reload
service apache2 restart
service varnish restart
cp $templates/varnish.vcl /etc/varnish/default.vcl
cp $templates/varnish.default /etc/default/varnish

# elasticsearch scripts
# wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
# apt-get install apt-transport-https
# echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-7.x.list
# apt-get update
# apt -y install elasticsearch
# service elasticsearch start
# systemctl enable elasticsearch
