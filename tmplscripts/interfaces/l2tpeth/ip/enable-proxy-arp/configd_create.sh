#!/opt/vyatta/bin/cliexec
echo 1 > /proc/sys/net/ipv4/conf/$VAR(../../@)/proxy_arp
