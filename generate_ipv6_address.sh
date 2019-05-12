


IP=$(hostname -I | cut -f2 -d' '| cut -f1-4 -d:)
array=( 1 2 3 4 5 6 7 8 9 0 a b c d e f )
a=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}
b=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}
c=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}
d=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}
MNIP=$IP:$a:$b:$c:$d
ip -6 addr add $MNIP/64 dev $(ip addr show | awk '/inet.*brd/{print $NF}')
export MNIP

