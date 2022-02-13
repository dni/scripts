#!/bin/sh
templates="~/scripts/server/templates"
username="magento2"

sh ~/scripts/server/install.sh
sh ~/scripts/server/user.sh $username
sh ~/scripts/server/php.sh $username

# varnish
apt-get install -y varnish
cp $templates/$username/varnish.vcl /etc/varnish/default.vcl
cp $templates/$username/varnish.default /etc/default/varnish
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

touch /root/.setup_done
