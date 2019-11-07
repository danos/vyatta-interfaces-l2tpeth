#!/opt/vyatta/bin/cliexec
echo 0 > /proc/sys/net/ipv4/conf/$VAR(../../@)/forwarding
