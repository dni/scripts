#!/bin/sh
tmux_env() {
  tmux new-session -d -s work

  tmux new-session -s system   -n htop -d 'htop; zsh'
  tmux new-window  -t system:1 -n jackd   'jackd -R -d net -a 192.168.1.140; zsh'
  tmux new-window  -t system:2 -n pactl   'sleep 5;pactl load-module module-jack-source; zsh'

  tmux new-session -s message   -n mail -d 'mutt; zsh'
  tmux new-window  -t message:1 -n irc     'irssi; zsh'

  tmux new-session -s vms   -n typo3 -d 'cd ~/repos/hostinghelden-typo3; vagrant up; vagrant ssh'
  tmux new-window  -t vms:1 -n magento2 'cd ~/repos/hostinghelden-magento2; vagrant up; vagrant ssh'

  tmux new-session -s server   -n server -d 'ssh h1'
  tmux new-window  -t server:1 -n typo3_1   'ssh m2'
  tmux new-window  -t server:2 -n typo3_2   'ssh typo3_1'
  tmux new-window  -t server:3 -n magento2  'ssh typo3_2'
  tmux new-window  -t server:4 -n btcpay    'ssh btcpay'
}
