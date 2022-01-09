#!/bin/sh
# this is the arch linux install script, by dni <3

echo "install cli programs"
sudo pacman -S --noconfirm vim zsh fzf rg jq git curl htop maim dmenu dunst dnsutils pass pass-otp zbar openssh wireguard-tools sxhkd pulseaudio yay compton

echo "install fonts"
sudo pacman -S --noconfirm ttf-roboto ttf-droid ttf-font-awesome ttf-inconsolata

echo "install gnome programs"
sudo pacman -S --noconfirm gnome-control-center gnome-contacts gnome-calculator gnome-tweaks

echo "install gui programs"
sudo pacman -S --noconfirm firefox thunderbird nautilus libreoffice pavucontrol arandr vlc gimp inkscape fractal discord signal-desktop qtpass

echo "dotfiles"
git clone git@github.com:dni/.dotfiles ~/.dotfiles
git clone git@github.com:dni/scripts ~/scripts
cd  ~/.dotfiles
sh dotfiles

mkdir ~/repos
source ~/.profile
echo "build dwm"
build-dwm
echo "build st"
build-st

# set gnome apps to darkmode
gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark

echo "rebooting..."
reboot
