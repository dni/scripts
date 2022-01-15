username="magento2"
templates="~/scripts/server/templates"
wwwdir="/var/www"
efs_ip="172.31.26.179"
mediadir="/var/www/media"
php_ini="/etc/php/${php_version}/apache2/php.ini"
composer_path="/usr/local/bin/composer"
php_version=8.1
git_server="git.hostinghelden.at"

useradd -G www-data $user
# usermod -a -G www-data $username
mkdir -p /home/#{username}/.composer
cp ~/scripts/server/templates/auth.json /home/$username/.composer/auth.json

# TODO: ssh not functional atm
mkdir -p /home/$username/.ssh

cp ~/scripts/server/templates/private/gitkey /home/$username/.ssh/id_rsa
chmod 600 /home/$username/.ssh/id_rsa

echo "Host $git_server
  StrictHostKeyChecking no
  IdentityFile ~/.ssh/id_rsa" > /home/$username/.ssh/config
chmod 600 /home/$username/.ssh/config

chown -R $username /home/$username/


mkdir -p $wwwdir
chown -R $username:www-data $wwwdir

echo "$username ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# mount amazon efs disk
apt-get install -y nfs-common
mkdir -p $mediadir
chown -R $username:www-data $mediadir
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport $efs_ip:/ $mediadir

# install custom repo for php
add-apt-repository ppa:ondrej/apache2
add-apt-repository ppa:ondrej/php
apt-get update

php_version=8.1
apt-get install -y php${php_version} php${php_version}-dev php${php_version}-gd php${php_version}-mysqli php${php_version}-mbstring php${php_version}-soap php${php_version}-zip php${php_version}-xml php${php_version}-bcmath php${php_version}-curl php${php_version}-intl
a2enmod php${php_version} rewrite headers expires ssl proxy proxy_http
update-alternatives --set php /usr/bin/php${php_version}


# apache blacklist
cp ~/scripts/server/templates/blacklist.conf /etc/apache2/blacklist.conf
echo 'ServerTokens Prod' >> /etc/apache2/apache2.conf
echo 'ServerSignature Off' >> /etc/apache2/apache2.conf

# install composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar ${composer_path}

# wkhtmltopdf
apt install -y wkhtmltopdf xvfb

# crontab script
echo "TODO" > /srv/crontab.sh
chmod +x /srv/crontab.sh
cron "configure cronjob" do
  minute "*"
  user "magento2"
  command "/srv/crontab.sh"
end

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
