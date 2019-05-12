#!/bin/bash
# Zeon Masternode generate ipv6 address  V1.1 for Ubuntu 16.04 ,18.04 and 18.10 LTS
# (c) 2019 by Pubfred zeonmymail(at)gmail.com  for Zeon 
#
# Script will attempt to generate a public IPV6 address
# and add the address to Network interface 
#
# Usage:
# bash generate_ipv6_address.sh
#

#Color codes
RED='\033[0;91m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color


# Get IPv6 from Hostname and take the 4 first 
IP=$(hostname -I | cut -f2 -d' '| cut -f1-4 -d:)
array=( 1 2 3 4 5 6 7 8 9 0 a b c d e f )
a=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}
b=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}
c=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}
d=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}
# Generate a random IPv6 in address range  
MNIP=$IP:$a:$b:$c:$d
# Add address to Interface 
ip -6 addr add $MNIP/64 dev $(ip addr show | awk '/inet.*brd/{print $NF}')
# Export address for use in next script 
export MNIP


# Install Netplan file 
if [[ $(lsb_release -rs) > "17.04" ]]; then
     if [ ! -f /etc/netplan/50-cloud-init.yaml ]; then 
sudo tee <<EOF  /etc/netplan/50-cloud-init.yaml  >/dev/null
network:
  version: 2
  renderer: networkd
  ethernets:
    $(ip addr show | awk '/inet.*brd/{print $NF}'):
      dhcp4: yes
      addresses:
        - '$MNIP/64'
EOF

sudo netplan apply 
     else 
        echo "        - '$MNIP/64'" >> /etc/netplan/50-cloud-init.yaml
        sudo netplan apply 
     fi
fi

# Install Netplan file 
if [[ $(lsb_release -rs) < "17.04" ]]; then
    echo -e "${RED}Please Upgrade Ubuntu version to newier version \n  ${NC}"
    read -p " Upgrade Ubuntu version  (y/n)?  " CONT
   if [ "$CONT" = "y" ]; then
      # Start a new install 
       sudo do-release-upgrade
   else
      exit 0;
   fi
fi


echo -e "${GREEN}This IPV6 Address will be use for next Masternode install :\n $MNIP ${NC}"
read -p "Continue to bash Zeon_Master_setup_ipv6.sh  (y/n)?  " CONT
   if [ "$CONT" = "y" ]; then
      # Start a new install 
      bash Zeon_Master_setup_ipv6.sh;
   else
      exit 0;
   fi




