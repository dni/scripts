#!/bin/sh

# essentials
apt-get update
apt-get upgrade -y
apt-get install -y stow htop tree curl zip apt-utils zsh

chsh root -s /bin/zsh

# dotfiles for root user
git clone https://github.com/dni/.dotfiles /root/.dotfiles
cd /root/.dotfiles
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

# opsworks hosts
touch /etc/aws/opsworks/skip-hosts-update

# internal subnet access to git
echo '172.31.53.159 git.dnilabs.com' >> /etc/hosts
