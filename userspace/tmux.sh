#!/bin/sh
tmux_env() {
  tmux new-session -d -s work

  tmux new-session -s system   -n htop -d 'htop; zsh'
  tmux new-window  -t system:1 -n jackd   'jackd -R -d net -a 192.168.1.140; zsh'
  tmux new-window  -t system:2 -n pactl   'zsh'

  tmux new-session -s message   -n mail -d 'mutt; zsh'
  tmux new-window  -t message:1 -n irc     'irssi; zsh'

  tmux new-session -s vms   -n typo3 -d 'cd ~/repos/opsworks-typo3; vagrant up; vagrant ssh'
  tmux new-window  -t vms:1 -n magento2 'cd ~/repos/opsworks-magento2; vagrant up; vagrant ssh'
  tmux new-window  -t vms:2 -n odoo     'cd ~/repos/odoo; vagrant up; vagrant ssh; sudo su; su -- odoo8; cd; python odoo.py'

  tmux new-session -s server   -n server -d 'ssh s1'
  tmux new-window  -t server:1 -n typo3_1   'ssh typo3_1'
  tmux new-window  -t server:2 -n typo3_2   'ssh typo3_2'
  tmux new-window  -t server:3 -n magento2  'ssh m2'
  tmux new-window  -t server:3 -n raspberry 'ssh pi'
  tmux new-window  -t server:4 -n a300      'ssh a300'
}

tmux_env_lnbits_boltz() {
  user_dir="/home/dni"
  repo_dir="$user_dir/repos"
  boltz_dir="$repo_dir/boltz-backend"
  mempool_dir="$repo_dir/mempool"
  lnbits_dir="$repo_dir/stream/lnbits-legend-boltz/"
  lnbits_cmd="./venv/bin/uvicorn lnbits.__main__:app --port 5000 --reload"
  electrs_cmd="./target/release/electrs --daemon-dir $mempool_dir/electrs --network regtest --cookie-file $cookie --electrum-rpc-addr 0.0.0.0:50003"
  cookie="$boltz_dir/docker/regtest/data/core/cookies/.bitcoin-cookie"

  sudo systemctl start docker
  docker start regtest
  echo "waiting 5s for docker regtest to come up..."
  sleep 15

  rm $user_dir/.boltz/boltz.db

  rpc_password=$(cat $cookie | cut -d ":" -f 2)
  sed -i -e "/CORE_RPC_PASSWORD/ s/\"[^\"][^\"]*\"/\"$rpc_password\"/" $mempool_dir/docker/docker-compose.yml

  tmux new-session -s lnbits   -n cli    -d "source $boltz_dir/docker/docker-scripts.sh; cd $lnbits_dir; zsh"
  tmux new-window  -t lnbits:1 -n editor    "cd $lnbits_dir; vim .;zsh"
  tmux new-window  -t lnbits:2 -n lnbits    "cd $lnbits_dir; $lnbits_cmd; zsh"
  tmux new-window  -t lnbits:3 -n boltz     "cd $boltz_dir; npm run dev; zsh"
  tmux new-window  -t lnbits:4 -n electrs   "cd $repo_dir/electrs/; $electrs_cmd; zsh"
  tmux new-window  -t lnbits:5 -n mempool   "cd $mempool_dir/docker/; docker-compose up; zsh"

  sleep 15
  docker network connect mempool regtest 2> /dev/null
  docker network connect mempool docker-api-1 2> /dev/null
  tmux ls
}
