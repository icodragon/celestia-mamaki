#!/bin/bash

#Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
COLOR_OFF='\033[0m'
DRAGON="$GREEN[Dragon]$COLOR_OFF"

bash_profile=$HOME/.bash_profile
if [ -f "$bash_profile" ]; then
    . $HOME/.bash_profile
fi
echo -e "$DRAGON hello! I'm telegram: ${GREEN}https://t.me/icodragon | My discord: icodragon#4560${COLOR_OFF}" && sleep 1
echo -e "$DRAGON Update repositories.." && sleep 1
sudo apt update && sudo apt upgrade -y
echo -e "$DRAGON Install: curl tar wget clang pkg-config libssl-dev jq build-essential bsdmainutils git make ncdu" && sleep 1
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential bsdmainutils git make ncdu -y
go version
if [[ ! $? -eq 0 ]]
then
  cd $HOME
  ver="1.17.2"
  wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
  rm "go$ver.linux-amd64.tar.gz"
  echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
  . $HOME/.bash_profile
  go version
else
  echo -e "$DRAGON Go already installed." && sleep 1
fi

#Download build
echo -e "$DRAGON Download celestia-app (check version build)"
cd $HOME
if [ ! -d "$HOME/celestia-app" ]; then
  git clone https://github.com/celestiaorg/celestia-app
  cd celestia-app
  git fetch
  git checkout v0.5.2
  make install
else
  echo -e "$DRAGON Directory exists ($HOME/celestia-app). 
  If you aborted the installation, use the command: rm -rf $HOME/celestia-app"
fi

#Settings vars
cd $HOME
CELESTIA_CHAIN="mamaki"
echo -e "$DRAGON Set сhain name: $CELESTIA_CHAIN" && sleep 1

if [ ! $CELESTIA_NODENAME ]; then
read -p "Enter any name node: " CELESTIA_NODENAME
echo 'export CELESTIA_NODENAME='\"${CELESTIA_NODENAME}\" >> $HOME/.bash_profile
fi

if [ ! $CELESTIA_WALLET ]; then
CELESTIA_WALLET=$CELESTIA_NODENAME
echo 'export CELESTIA_WALLET='\"${CELESTIA_WALLET}\" >> $HOME/.bash_profile
fi
echo -e "$DRAGON Set nodename: $CELESTIA_NODENAME and wallet name: $CELESTIA_WALLET" && sleep 1

#init
echo -e "$DRAGON init node: $CELESTIA_NODENAME"
celestia-appd init $CELESTIA_NODENAME --chain-id $CELESTIA_CHAIN && sleep 1
celestia-appd config chain-id $CELESTIA_CHAIN && sleep 1
celestia-appd config keyring-backend test && sleep 1

echo -e "$DRAGON Download genesis.json and (settings peers, settings node)"
wget -O $HOME/.celestia-app/config/genesis.json "https://github.com/celestiaorg/networks/raw/master/mamaki/genesis.json" && sleep 1
peers=$(curl -sL https://raw.githubusercontent.com/celestiaorg/networks/master/mamaki/peers.txt | tr -d '\n' | head -c -1) && echo $peers
sed -i.bak -e "s/^persistent-peers *=.*/persistent-peers = \"$peers\"/" $HOME/.celestia-app/config/config.toml
sed -i.bak -e "s/^timeout-commit *=.*/timeout-commit = \"25s\"/" $HOME/.celestia-app/config/config.toml
sed -i.bak -e "s/^skip-timeout-commit *=.*/skip-timeout-commit = false/" $HOME/.celestia-app/config/config.toml
sed -i.bak -e "s/^mode *=.*/mode = \"validator\"/" $HOME/.celestia-app/config/config.toml
sed -i.bak -e "s/^use-legacy *=.*/use-legacy = \"true\"/" $HOME/.celestia-app/config/config.toml

#save!
echo -e "$DRAGON Create wallet."
celestia-appd keys add $CELESTIA_WALLET --keyring-backend test
echo -e "$DRAGON Please save memonic."
read -p "Ready? send ENTER."
sleep 1

echo -e "$DRAGON Create service"
#create service
tee $HOME/celestia-appd.service > /dev/null <<EOF
[Unit]
  Description=CELESTIA MAMAKI
  After=network-online.target
[Service]
  User=$USER
  ExecStart=$(which celestia-appd) start
  Restart=on-failure
  RestartSec=10
  LimitNOFILE=65535
[Install]
  WantedBy=multi-user.target
EOF
sleep 1
sudo mv $HOME/celestia-appd.service /etc/systemd/system

echo -e "$DRAGON Start node."
sudo systemctl enable celestia-appd && sleep 1
sudo systemctl daemon-reload && sleep 1
sudo systemctl restart celestia-appd && sleep 1
sleep 1

if [[ `service celestia-appd status | grep active` =~ "running" ]]
then
  echo -e "$DRAGON Node Celestia is running."
  echo -e "Check status node: ${BLUE}curl localhost:26657/status${COLOR_OFF}"
  echo -e "Check logs: ${BLUE}journalctl -u celestia-appd -f -o cat${COLOR_OFF}"
  echo -e "Feedback: ${BLUE}https://t.me/icodragon${COLOR_OFF} Discord: ${BLUE}icodragon#4560${COLOR_OFF}"
else
  echo -e "$DRAGON ${RED}Node Celestia don't running. Please install node in manual mode.${COLOR_OFF}"
fi
