#!/bin/sh

# essentials
apt-get update
apt-get upgrade
apt install vim zsh tmux htop

# dotfiles
git clone git@github.com:dni/.dotfiles ~
git clone git@github.com:dni/scripts ~

cd ~/.dofiles
chmod +x dotfiles
./dotfiles install_vim
./dotfiles install_zsh
./dotfiles install_tmux

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
chsh zsh
