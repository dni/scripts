#!/bin/sh
if [ -e /root/.setup_done ]; then
  echo "setup already ran. delete /root/.setup_done to run it again"
  exit 0
fi

export DEBIAN_FRONTEND=noninteractive

username="magento2"
templates="/root/scripts/server/templates/$username"
php_version=7.4

git clone https://github.com/dni/scripts ~/scripts
sh ~/scripts/server/ubuntu.sh
sh ~/scripts/server/ubuntu/apache2.sh
sh ~/scripts/server/ubuntu/php.sh $php_version
sh ~/scripts/server/templates/magento2/php-ini.sh $php_version
sh ~/scripts/server/ubuntu/user.sh $username

# varnish
apt-get install -y varnish
cp $templates/varnish.vcl /etc/varnish/default.vcl
cp $templates/varnish.default /etc/default/varnish
sed -i "s/Listen 80.*/Listen 8080/" /etc/apache2/ports.conf
sed -i -e "s/6081/80 -p feature=+esi_ignore_https/g" -e "s/256m/512m/g" /etc/systemd/system/multi-user.target.wants/varnish.service
sed -i -e "s/6081/80 -p feature=+esi_ignore_https/g" -e "s/256m/512m/g" /lib/systemd/system/varnish.service
systemctl daemon-reload
service apache2 restart
service varnish restart

# elasticsearch scripts
# wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
# apt-get install apt-transport-https
# echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-7.x.list
# apt-get update
# apt -y install elasticsearch
# service elasticsearch start
# systemctl enable elasticsearch

# crontab script
cp $templates/crontab.sh /srv/crontab.sh
chmod +x /srv/crontab.sh
crontab -u $username $templates/crontab.txt

# dotfiles for $username
d_dir="/home/$username/.dotfiles"
chsh $username -s /bin/zsh
git clone https://github.com/dni/.dotfiles $d_dir
chown $username -R $d_dir
chmod +x $d_dir/dotfiles
su - $username -c "cd $d_dir; ./dotfiles install_server"

apt-get autoremove -y > /dev/null

touch /root/.setup_done
