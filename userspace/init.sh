#!/usr/bin/env sh

# xinit hook
xinit_hook() {
  sh /etc/X11/xinit/xinitrc.d/50-systemd-user.sh & # gnome keyring
  sh ~/.config/screenlayout/dualscreen.sh &
  [ -e ~/.fehbg ] && sh ~/.fehbg & # background
  mousekeyboard & # mouse keyboard settings
  jackd -R -d net -a 192.168.1.140 &
  sleep 4
  pactl load-module module-jack-sink &
}

xinit_die() {
  killall xinit
  killall jackd
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
