#!/bin/sh

# essentials
apt-get update
apt-get upgrade
apt install -y vim zsh tmux htop stow fzf ranger tree

apt install -y apache2 imagemagick graphicsmagick curl zip dialog apt-utils

# dotfiles
cd
git clone git@github.com:dni/.dotfiles
git clone git@github.com:dni/scripts
cd .dotfiles
chmod +x dotfiles
./dotfiles install_server

# swap
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile    none    swap    sw    0   0" >> /etc/fstab

# datetime
locale-gen de_DE.UTF-8
update-locale LANG=de_DE.UTF-8 LC_MESSAGES=POSIX
dpkg-reconfigure -f noninteractive tzdata
timedatectl set-timezone Europe/Vienna
echo "Europe/Vienna" > /etc/timezone

# change shell
# chsh -s zsh root

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
zend_extension=xdebug
xdebug.mode = debug
xdebug.start_with_request = yes
EOF

service apache2 restart

echo ":VimspectorInstall vscode-php-debug --sudo"
echo "for xcode debugging"
