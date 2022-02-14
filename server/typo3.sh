#!/bin/sh
if [ -e /root/.setup_done ]; then
  echo "setup already ran. delete /root/.setup_done to run it again"
  exit 0
fi

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

npm i -g pm2 n
n stable

git clone git@git.dnilabs.com:critical-css-service.git /srv/critical-css-service
chown $username -R /srv/critical-css-service/
su - $username -c "cd /srv/critical-css-service/; npm i"
su - $username -c "pm2 start -f index.js"

# crontab script
templates="/root/scripts/server/templates/$username"
cp $templates/crontab.sh /srv/crontab.sh
chmod +x /srv/crontab.sh
crontab -u $username $templates/crontab.txt

apt-get autoremove -y /dev/null

touch /root/.setup_done

# dotfiles for typo3 user
chsh typo3 -s /bin/zsh
sudo su typo3
git clone https://github.com/dni/.dotfiles /home/typo3/.dotfiles
cd /home/typo3/.dotfiles
chmod +x dotfiles
./dotfiles install_server
