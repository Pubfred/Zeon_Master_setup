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
ip -6 addr add $MNIP/64 dev $(netstat -i | grep '^[a-z]' | awk '{print $1}' | grep -v 'lo'  | head -1 )

echo -e "${GREEN}This IPV6 Address will be use for next Masternode install :\n $MNIP ${NC}"

exit 0;
