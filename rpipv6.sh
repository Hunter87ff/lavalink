#!/bin/bash

count=0
cmd_ip="/sbin/ip"
cmd_awk="/usr/bin/awk"
cmd_head="/usr/bin/head"
squid_confd="/etc/squid/conf.d/"
interface="eth0"
sleeptime="30s"

# Get IPv6 network prefix
network=$($cmd_ip -o -f inet6 addr show dev $interface | $cmd_awk '/scope global/ {print $4}')
if [ -z "$network" ]; then
  echo "No global IPv6 network found on $interface"
  exit 1
fi
echo "Network: $network"

# Create squid configuration directory if it doesn't exist
if [ ! -d "$squid_confd" ]; then
  mkdir -p $squid_confd
fi

# Generate Random Address
GenerateAddress() {
  array=( 1 2 3 4 5 6 7 8 9 0 a b c d e f )
  a=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}
  b=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}
  c=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}
  d=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}
  echo $network:$a:$b:$c:$d
}

# Run IPv6-Address-Loop
while true
do
  ip1=$(GenerateAddress)
  echo "[+] add ip1 $ip1"

  $cmd_ip -6 addr add $ip1/64 dev $interface
  echo "acl ip1 random 1/3
tcp_outgoing_address $ip1 ip1" > $squid_confd"01-random-ip1.conf"

  if [[ $count > 0 ]]; then
    echo "[-] del ip2 $ip2"
    $cmd_ip -6 addr del $ip2/64 dev $interface
    rm $squid_confd"66-random-ip2.conf" > /dev/null 2>&1
  fi
  /bin/systemctl reload squid
  sleep $sleeptime

  ip2=$(GenerateAddress)
  echo "[+] add ip2 $ip2"

  $cmd_ip -6 addr add $ip2/64 dev $interface
  echo "acl ip2 random 1/2
tcp_outgoing_address $ip2 ip2" > $squid_confd"02-random-ip2.conf"

  if [[ $count > 0 ]]; then
    echo "[-] del ip3 $ip3"
    $cmd_ip -6 addr del $ip3/64 dev $interface
    rm $squid_confd"66-random-ip3.conf" > /dev/null 2>&1
  fi
  /bin/systemctl reload squid
  sleep $sleeptime

  ip3=$(GenerateAddress)
  echo "[+] add ip3 $ip3"
  $cmd_ip -6 addr add $ip3/64 dev $interface
  echo "acl ip3 random 1/1
tcp_outgoing_address $ip3 ip3" > $squid_confd"03-random-ip3.conf"

  echo "[-] del ip1 $ip1"
  $cmd_ip -6 addr del $ip1/64 dev $interface
  rm $squid_confd"66-random-ip1.conf" > /dev/null 2>&1
  ((count++))
  /bin/systemctl reload squid
  sleep $sleeptime
done
