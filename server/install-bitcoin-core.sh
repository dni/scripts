#!/bin/sh
#apt install -y

username="btcnode"
useradd $username
passwd $username
mkdir /home/$username
chown btc:btc /home/$username

#echo "choose partition to mount from into home directory"
#mount $disk /home/$username

echo "installing dependencies..."
apt install -y autoconf automake build-essential libtool autotools-dev pkg-config bsdmainutils python3 libevent-dev libboost-dev libboost-system-dev libboost-filesystem-dev libboost-test-dev libgmp-dev libsqlite3-dev python3-mako net-tools zlib1g-dev libsodium-dev gettext

echo "building bitcoin core..."
git clone https://github.com/bitcoin/bitcoin/ /home/btcnode/bitcoin_source
cd /home/btcnode/bitcoin_source
./autogen.sh
./configure --without-wallet --without-gui --without-miniupnpc
make
make install

echo "building c lightning..."
pip3 install --user mrkd mistune==0.8.4
git clone https://github.com/ElementsProject/lightning.git
cd lightning
# TESTING
# apt install -y valgrind libpq-dev shellcheck cppcheck libsecp256k1-dev jq
# pip3 install --upgrade pip
# pip3 install --user -r requirements.txt
./configure
make
make install

echo "bitcoind &
./lightningd/lightningd &
./cli/lightning-cli help"
