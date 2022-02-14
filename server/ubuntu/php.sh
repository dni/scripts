php_version=7.4
composer_path="/usr/local/bin/composer"

echo "##### php.sh START #####"

# install custom repo for php
add-apt-repository ppa:ondrej/apache2
add-apt-repository ppa:ondrej/php
apt-get update > /dev/null

apt-get install -y php${php_version} php${php_version}-dev php${php_version}-gd php${php_version}-mysqli php${php_version}-mbstring php${php_version}-soap php${php_version}-zip php${php_version}-xml php${php_version}-bcmath php${php_version}-curl php${php_version}-intl > /dev/null

update-alternatives --set php /usr/bin/php${php_version}

a2enmod php${php_version}

# install composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar ${composer_path}

echo "##### php.sh END #####"
