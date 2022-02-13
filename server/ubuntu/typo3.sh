#!/bin/sh
if [ -e /root/.setup_done]; then
  echo "setup already ran. delete /root/.setup_done to run it again"
  exit 1
fi

username="typo3"

git clone https://github.com/dni/scripts ~/scripts

sh ~/scripts/server/ubuntu/install.sh
sh ~/scripts/server/ubuntu/user.sh $username
sh ~/scripts/server/ubuntu/php.sh $username

# critical css service
git clone git@git.dnilabs.com:critical-css-service.git /srv/critical-css-service
chown $username -R /srv/critical-css-service/

apt install -y npm nodejs libpangocairo-1.0-0 libx11-xcb1 libxcomposite1 libxcursor1 \
  libxdamage1 libxi6 libxtst6 libnss3 libcups2 libxss1 libxrandr2 libgconf2-4 libasound2 \
  libatk1.0-0 libgtk-3-0

npm i -g pm2 n
n stable
su - $username -c "cd /srv/critical-css-service/; npm i; pm2 start -f index.js"

touch /root/.setup_done
