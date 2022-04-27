#!/bin/sh

export DEBIAN_FRONTEND=noninteractive

echo "##### ubuntu.sh START #####"

# essentials
apt-get update > /dev/null
apt-get upgrade -y > /dev/null
apt-get install -y stow htop tree curl zip apt-utils zsh > /dev/null
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
echo "Europe/Vienna" > /etc/timezone
locale-gen de_DE.UTF-8
update-locale LANG=de_DE.UTF-8 LC_MESSAGES=POSIX
dpkg-reconfigure -f noninteractive tzdata
timedatectl set-timezone Europe/Vienna

# opsworks hosts
touch /etc/aws/opsworks/skip-hosts-update

# internal subnet access to git
echo '172.31.11.72 git.dnilabs.com' >> /etc/hosts

echo "##### ubuntu.sh END #####"
