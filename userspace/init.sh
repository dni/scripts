#!/usr/bin/env sh

# xinit hook
xinit_hook() {
  sh /etc/X11/xinit/xinitrc.d/50-systemd-user.sh & # gnome keyring
  ~/.config/screenlayout/dualscreen
  [ -e ~/.fehbg ] && sh ~/.fehbg & # background
  mousekeyboard & # mouse keyboard settings
  gsettings set org.gnome.desktop.interface color-scheme prefer-dark
}

xinit_die() {
  killall xinit
}

mousekeyboard() {
  xinput --set-prop "Razer Razer DeathAdder" "libinput Left Handed Enabled" 1
  xinput --set-prop "Razer Razer DeathAdder" "libinput Accel Profile Enabled" 0, 0
  xset r rate 200 40
  setxkbmap de
  xmodmap -e "keysym Caps_Lock = Escape"
  xmodmap -e "clear lock"
  numlockx
}
