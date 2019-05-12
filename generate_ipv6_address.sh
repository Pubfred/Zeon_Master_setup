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

echo $MNIP



