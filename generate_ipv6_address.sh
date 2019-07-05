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
IP=$(dig -6 TXT +short o-o.myaddr.l.google.com @ns1.google.com | awk -F'"' '{ print $2}'  | cut -f2 -d' '| cut -f1-4 -d:)

if [ -z "$Ip" ]; then
array=( 1 2 3 4 5 6 7 8 9 0 a b c d e f )
a=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}
b=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}
c=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}
d=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}
# Generate a random IPv6 in address range  
MNIP=$IP:$a:$b:$c:$d
# Add address to Interface 
ip -6 addr add $MNIP/64 dev $(netstat -i | grep '^[a-z]' | awk '{print $1}' | grep -v 'lo')
# Export address for use in next script 
export MNIP

else
    echo -e "${RED}ERROR:${YELLOW} Public IPV6 Address was not detected!${NC} \a"
    echo -e "${YELLOW}  Problem  with VPS IPV6 ... see VPS documentation ${NC} \a"
    exit 1 ; 
fi



# Install Netplan file 
if [[ $(lsb_release -rs) > "17.04" ]]; then
     if [ ! -f /etc/netplan/01-netcfg.yaml ]; then 
sudo tee <<EOF  /etc/netplan/01-netcfg.yaml  >/dev/null
network:
  version: 2
  renderer: networkd
  ethernets:
    $(netstat -i | grep '^[a-z]' | awk '{print $1}' | grep -v 'lo'  | head -1 ):
      dhcp4: yes
      addresses:
      - $MNIP/64
EOF

sudo netplan apply 
     else 
         if [ -s "/etc/netplan/01-netcfg.yaml" ] ; then
            echo "      - $MNIP/64" >> /etc/netplan/01-netcfg.yaml
            sudo netplan apply 
         else
sudo tee <<EOF  /etc/netplan/01-netcfg.yaml  >/dev/null
network:
  version: 2
  renderer: networkd
  ethernets:
    $(netstat -i | grep '^[a-z]' | awk '{print $1}' | grep -v 'lo'):
      dhcp4: yes
      addresses:
      - $MNIP/64
EOF

sudo netplan apply
         
         fi
       # echo -e "${RED}After install add this line to /etc/netplan/50-cloud-init.yaml \n  ${NC}"
       # echo -e "${YELLOW} - $MNIP/64 \n  ${NC}"
       # echo -e "${GREEN} And issue this command : sudo netplan apply --debug \n  ${NC}"
       # echo "        - '$MNIP/64'" >> /etc/netplan/50-cloud-init.yaml
       # sudo netplan apply 
     fi
fi

# Install Netplan file 
if [[ $(lsb_release -rs) < "17.04" ]]; then
    echo -e "${RED}Please Upgrade Ubuntu version to newier version \n  ${NC}"
    read -p " Upgrade Ubuntu version  (y/n)?  " CONT
   if [ "$CONT" = "y" ]; then
      # Start a new install 
       sudo do-release-upgrade
       exit 1;
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




