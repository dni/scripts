apt install awscli mysql-client
aws configure set preview.cloudfront true

## install yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
apt-get update && apt-get install -y yarn

## python3.8 support and ubuntu magic
apt install libncurses-dev python3.8 python3.8-dev
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 1
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 2
update-alternatives --install /usr/bin/python3-config python3-config /usr/bin/python3.6-config 1
update-alternatives --install /usr/bin/python3-config python3-config /usr/bin/python3.8-config 2

update-alternatives --config python3
update-alternatives --config python3-config

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

make
make install

apt install php7.4-dev php-pear php7.4-xdebug
phpenmod -v 7.4 xdebug

cat <<'EOF' >> /etc/php/7.4/apache2/php.ini
zend_extension=xdebug.so
xdebug.mode = debug
xdebug.start_with_request = yes
EOF

service apache2 restart

echo ":VimspectorInstall vscode-php-debug --sudo"
echo "for xcode debugging"