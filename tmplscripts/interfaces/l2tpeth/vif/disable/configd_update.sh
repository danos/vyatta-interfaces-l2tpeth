#!/opt/vyatta/bin/cliexec
ifname=$VAR(../../@).$VAR(../@)
[ -d /sys/class/net/$ifname ] || exit 0
ip link set $ifname down
