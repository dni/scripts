php_version=7.4

echo "##### devtools.sh START #####"

export DEBIAN_FRONTEND=noninteractive

apt-get install -y awscli mysql-server mysql-client > /dev/null
aws configure set preview.cloudfront true

## install yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
apt-get update > /dev/null
apt-get install -y yarn > /dev/null

## python3.8 support and ubuntu magic
apt-get install -y libncurses-dev python3.8 python3.8-dev > /dev/null
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 1
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 2
# update-alternatives --install /usr/bin/python3-config python3-config /usr/bin/python3.6-config 1
update-alternatives --install /usr/bin/python3-config python3-config /usr/bin/python3.8-config 1
update-alternatives --set python3 /usr/bin/python3.8
update-alternatives --set python3-config /usr/bin/python3.8-config

# compile vim with python3.8 support
cd /tmp/
git clone https://github.com/vim/vim.git
cd vim
LDFLAGS="-rdynamic" ./configure --with-features=huge \
  --enable-multibyte \
  --enable-rubyinterp=yes \
  --enable-python3interp=yes \
  --with-python3-command=python3.8 \
  --with-python3-config-dir=$(python3-config --configdir) \
  --enable-perlinterp=yes \
  --enable-luainterp=yes \
  --enable-cscope \
  --prefix=/usr/local

echo "make vim"
make &> /dev/null
echo "make install vim"
make install &> /dev/null

echo ":VimspectorInstall vscode-php-debug --sudo"
echo "for xcode debugging"

update-alternatives --set python3 /usr/bin/python3.6

apt-get install -y php$php_version-dev php-pear php$php_version-xdebug > /dev/null
phpenmod -v $php_version xdebug

echo "zend_extension=xdebug.so
xdebug.mode = debug
xdebug.start_with_request = yes" >> /etc/php/$php_version/apache2/php.ini

service apache2 restart

echo "##### devtools.sh END #####"
