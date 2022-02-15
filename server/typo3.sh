#!/bin/sh
if [ -e /root/.setup_done ]; then
  echo "setup already ran. delete /root/.setup_done to run it again"
  exit 0
fi

export DEBIAN_FRONTEND=noninteractive

username="typo3"

git clone https://github.com/dni/scripts ~/scripts
sh ~/scripts/server/ubuntu.sh
sh ~/scripts/server/ubuntu/apache2.sh
sh ~/scripts/server/ubuntu/php.sh
sh ~/scripts/server/ubuntu/user.sh $username

apt-get install -y imagemagick graphicsmagick wkhtmltopdf xvfb > /dev/null

# critical css service
apt-get install -y npm nodejs libpangocairo-1.0-0 libx11-xcb1 libxcomposite1 libxcursor1 \
  libxdamage1 libxi6 libxtst6 libnss3 libcups2 libxss1 libxrandr2 libgconf2-4 libasound2 \
  libatk1.0-0 libgtk-3-0 > /dev/null

npm i -g pm2 n > /dev/null
n stable > /dev/null
hash -r

cr_dir="/srv/critical-css-service"
git clone git@git.dnilabs.com:critical-css-service.git $cr_dir
chown $username -R $cr_dir
su - $username -c "cd $cr_dir; npm i > /dev/null"
su - $username -c "cd $cr_dir; pm2 start -f index.js"

# crontab script
templates="/root/scripts/server/templates/$username"
cp $templates/crontab.sh /srv/crontab.sh
chmod +x /srv/crontab.sh
crontab -u $username $templates/crontab.txt

apt-get autoremove -y > /dev/null


# dotfiles for $username
d_dir="/home/$username/.dotfiles"
chsh $username -s /bin/zsh
git clone https://github.com/dni/.dotfiles $d_dir
chown $username -R $d_dir
chmod +x $d_dir/dotfiles
su - $username -c "cd $d_dir; ./dotfiles install_server"

touch /root/.setup_done
