#!/bin/bash
# Zeon Masternode Setup Script V1.3 for Ubuntu 16.04 and 18.04 LTS
# (c) 2018 by Pubfred zeonmymail(at)gmail.com  for Zeon 
#
# Script will attempt to autodetect primary public IP address
# and generate masternode private key unless specified in command line
#
# Usage:
# bash Zeon_Masternode_setup.sh [Masternode_Private_Key]
#
# Example 1: Existing genkey created earlier is supplied
# bash Zeon_Masternode_setup.sh 8qGKimjuDqF7aNAsMM8MVVKyhZuUPsuRSwh8fGGTneHpJaDdqoq
#
# Example 2: Script will generate a new genkey automatically
# bash Zeon_Masternode_setup.sh
#

#Color codes
RED='\033[0;91m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#Zeon TCP port
PORT=32222

#Clear keyboard input buffer
function clear_stdin { while read -r -t 0; do read -r; done; }

#Delay script execution for N seconds
function delay { echo -e "${GREEN}Sleep for $1 seconds...${NC}"; sleep "$1"; }

#Stop daemon if it's already running
function stop_daemon {
    if pgrep -x 'zeond' > /dev/null; then
        echo -e "${YELLOW}Attempting to stop zeond${NC}"
        zeon-cli stop
        delay 30
        if pgrep -x 'zeond' > /dev/null; then
            echo -e "${RED}zeond daemon is still running!${NC} \a"
            echo -e "${YELLOW}Attempting to kill...${NC}"
            pkill zeond
            delay 30
            if pgrep -x 'zeond' > /dev/null; then
                echo -e "${RED}Can't stop zeond! Reboot and try again...${NC} \a"
                exit 2
            fi
        fi
    fi
}

#Process command line parameters
genkey=$1

clear
echo -e "${YELLOW}Zeon Masternode Setup Script${NC}"
echo -e "${GREEN}Updating system and installing required packages...${NC}"
sudo apt-get update -y


# Determine primary public IP address
dpkg -s dnsutils 2>/dev/null >/dev/null || sudo apt-get -y install dnsutils
public_ip=$(dig +short myip.opendns.com @resolver1.opendns.com)

if [ -n "$public_ip" ]; then
    echo -e "${YELLOW}IP Address detected:" $public_ip ${NC}
else
    echo -e "${RED}ERROR:${YELLOW} Public IP Address was not detected!${NC} \a"
    clear_stdin
    read -e -p "Enter VPS Public IP Address: " public_ip
    if [ -z "$public_ip" ]; then
        echo -e "${RED}ERROR:${YELLOW} Public IP Address must be provided. Try again...${NC} \a"
        exit 1
    fi
fi

# update packages and upgrade Ubuntu
sudo apt-get -y upgrade
sudo apt-get -y dist-upgrade
sudo apt-get -y autoremove
sudo apt-get -y install wget nano htop jq
sudo apt-get -y install libzmq3-dev
sudo apt-get -y install libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev
sudo apt-get -y install libevent-dev

sudo apt -y install software-properties-common
sudo add-apt-repository ppa:bitcoin/bitcoin -y
sudo apt-get -y update
sudo apt-get -y install libdb4.8-dev libdb4.8++-dev

sudo apt-get -y install libminiupnpc-dev

sudo apt-get -y install fail2ban
sudo service fail2ban restart

sudo apt-get install ufw -y
sudo apt-get update -y

sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow $PORT/tcp
echo -e "${YELLOW}"
sudo ufw --force enable
echo -e "${NC}"

#Generating Random Password for zeond JSON RPC
rpcpassword=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

#Create 1GB swap file

if  [[ $(swapon -s | wc -l) -gt 1 ]] ; then
    echo -e "${GREEN}Skipping disk swap configuration...${NC} \n"
else
    echo -e "${YELLOW}Creating 1GB disk swap file. \nThis may take a few minutes!${NC} \a"
    
    sudo fallocate -l 1G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
     
    
    if [ $? -eq 0 ]; then
        sudo cp /etc/fstab /etc/fstab.bak
        echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
        sudo sysctl vm.vfs_cache_pressure=50
        sudo sysctl vm.swappiness=10
        echo -e "${GREEN}Swap was created successfully!${NC} \n"
    else
        echo -e "${YELLOW}Operation not permitted! Optional swap was not created.${NC} \a"
        rm /var/swap.img
    fi
fi

#Installing Daemon
cd ~
stop_daemon


# Deploy binaries to /usr/bin
if [[ `lsb_release -rs` == "16.04" ]] 
then
sudo cp ~/Zeon_Master_setup/zeon_daemon_16/zeon* /usr/bin/  
elif  [[ `lsb_release -rs` == "18.04" ]] 
then
sudo cp ~/Zeon_Master_setup/zeon_daemon_18/zeon* /usr/bin/  
fi
sudo chmod 755 -R ~/Zeon_Master_setup
sudo chmod 755 /usr/bin/zeon*

# Deploy masternode monitoring script
sudo cp ~/Zeon_Master_setup/nodemon.sh /usr/local/bin
sudo chmod 711 /usr/local/bin/nodemon.sh

#Create Zeon datadir
if [ ! -f ~/.zeon/zeon.conf ]; then 
	sudo mkdir ~/.zeon
fi

echo -e "${YELLOW}Creating zeon.conf...${NC}"

# If genkey was not supplied in command line, we will generate private key on the fly
if [ -z $genkey ]; then
 sudo bash -c 'cat <<EOF > ~/.zeon/zeon.conf'
rpcuser=zeonrpc
rpcpassword=$rpcpassword
EOF

    sudo chmod 755 -R ~/.zeon/zeon.conf

    #Starting daemon first time just to generate masternode private key
    zeond -daemon
    delay 30

    #Generate masternode private key
    echo -e "${YELLOW}Generating masternode private key...${NC}"
    genkey=$(zeon-cli masternode genkey)
    if [ -z "$genkey" ]; then
        echo -e "${RED}ERROR:${YELLOW}Can not generate masternode private key.$ \a"
        echo -e "${RED}ERROR:${YELLOW}Reboot VPS and try again or supply existing genkey as a parameter."
        exit 1
    fi
    
    #Stopping daemon to create zeon.conf
    stop_daemon
    delay 30
fi

# Create zeon.conf
cat <<EOF > ~/.zeon/zeon.conf
rpcuser=zeonrpc
rpcpassword=$rpcpassword
rpcallowip=127.0.0.1
onlynet=ipv4
listen=1
server=1
daemon=1
reindex=1
maxconnections=64
externalip=$public_ip
masternode=1
masternodeprivkey=$genkey
addnode=18.224.69.185
addnode=45.77.137.85
EOF

#Finally, starting Zeon daemon with new zeon.conf
zeond
delay 5

#Setting auto star cron job for zeond
cronjob="@reboot sleep 30 && zeond"
crontab -l > tempcron
if ! grep -q "$cronjob" tempcron; then
    echo -e "${GREEN}Configuring crontab job...${NC}"
    echo $cronjob >> tempcron
    crontab tempcron
fi
rm tempcron

echo -e "========================================================================
${YELLOW}Masternode setup is complete!${NC}
========================================================================

Masternode was installed with VPS IP Address: ${YELLOW}$public_ip${NC}

Masternode Private Key: ${YELLOW}$genkey${NC}

Now you can add the following string to the masternode.conf file
for your Hot Wallet (the wallet with your Zeon collateral funds):
======================================================================== \a"
echo -e "${YELLOW}mn1 $public_ip:$PORT $genkey TxId TxIdx${NC}"
echo -e "========================================================================

Use your mouse to copy the whole string above into the clipboard by
tripple-click + single-click (Dont use Ctrl-C) and then paste it 
into your ${YELLOW}masternode.conf${NC} file and replace:
    ${YELLOW}mn1${NC} - with your desired masternode name (alias)
    ${YELLOW}TxId${NC} - with Transaction Id from masternode outputs
    ${YELLOW}TxIdx${NC} - with Transaction Index (0 or 1)
     Remember to save the masternode.conf and restart the wallet!

To introduce your new masternode to the Zeon network, you need to
issue a masternode start command from your wallet, which proves that
the collateral for this node is secured."

clear_stdin
read -p "*** Press any key to continue ***" -n1 -s

echo -e "1) Wait for the node wallet on this VPS to sync with the other nodes
on the network. Eventually the 'IsSynced' status will change
to 'true', which will indicate a comlete sync, although it may take
from several minutes to several hours depending on the network state.
Your initial Masternode Status may read:
    ${YELLOW}Node just started, not yet activated${NC} or
    ${YELLOW}Node  is not in masternode list${NC}, which is normal and expected.

2) Wait at least until 'IsBlockchainSynced' status becomes 'true'.
At this point you can go to your wallet and issue a start
command by either using Debug Console:
    Tools->Debug Console-> enter: ${YELLOW}masternode start-alias mn1${NC}
    where ${YELLOW}mn1${NC} is the name of your masternode (alias)
    as it was entered in the masternode.conf file
    
or by using wallet GUI:
    Masternodes -> Select masternode -> RightClick -> ${YELLOW}start alias${NC}

Once completed step (2), return to this VPS console and wait for the
Masternode Status to change to: 'Masternode successfully started'.
This will indicate that your masternode is fully functional and
you can celebrate this achievement!

Currently your masternode is syncing with the Zeon network...

The following screen will display in real-time
the list of peer connections, the status of your masternode,
node synchronization status and additional network and node stats.
"
clear_stdin
read -p "*** Press any key to continue ***" -n1 -s

echo -e "
${GREEN}...scroll up to see previous screens...${NC}


Here are some useful commands and tools for masternode troubleshooting:

========================================================================
To view masternode configuration produced by this script in zeon.conf:

${YELLOW}cat ~/.zeon/zeon.conf${NC}

Here is your zeon.conf generated by this script:
-------------------------------------------------${YELLOW}"
cat ~/.zeon/zeon.conf
echo -e "${NC}-------------------------------------------------

NOTE: To edit zeon.conf, first stop the zeond daemon,
then edit the zeon.conf file and save it in nano: (Ctrl-X + Y + Enter),
then start the zeond daemon back up:

to stop:   ${YELLOW}zeon-cli stop${NC}
to edit:   ${YELLOW}nano ~/.zeon/zeon.conf${NC}
to start:  ${YELLOW}zeond${NC}
========================================================================
To view zeond debug log showing all MN network activity in realtime:

${YELLOW}tail -f ~/.zeon/debug.log${NC}
========================================================================
To monitor system resource utilization and running processes:

${YELLOW}htop${NC}
========================================================================
To view the list of peer connections, status of your masternode, 
sync status etc. in real-time, run the nodemon.sh script:

${YELLOW}nodemon.sh${NC}

or just type 'node' and hit <TAB> to autocomplete script name.
========================================================================


Enjoy your Zeon Masternode and thanks for using this setup script!

If you found it helpful, please donate Zeon to:
ZYFbfTSABh7hq2guBzSpkmiJGABX4NhLp9

...and make sure to check back for updates!

"
# Run nodemon.sh
# nodemon.sh

# EOF
