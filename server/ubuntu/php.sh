php_version=$1
composer_path="/usr/local/bin/composer"

if [ -z $php_version ]; then
  echo "no php version specified"
  exit 1
fi

echo "##### php.sh START #####"

# install custom repo for php
add-apt-repository -y ppa:ondrej/apache2
add-apt-repository -y ppa:ondrej/php
apt-get update > /dev/null

apt-get install -y php${php_version} php${php_version}-dev  php${php_version}-fpm php${php_version}-apcu php${php_version}-gd php${php_version}-mysqli php${php_version}-mbstring php${php_version}-soap php${php_version}-zip php${php_version}-xml php${php_version}-bcmath php${php_version}-curl php${php_version}-intl > /dev/null

update-alternatives --set php /usr/bin/php${php_version}

phpenmod -v $php_version opcache apcu
a2dismod php5
a2enmod php${php_version}
#locale-gen de_DE.UTF-8
#update-locale LANG=de_DE.UTF-8 LC_MESSAGES=POSIX

# install composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar ${composer_path}

echo "##### php.sh END #####"
