#!/opt/vyatta/bin/cliexec
if ! grep l2tp_eth /proc/modules > /dev/null; then
    modprobe l2tp_eth
fi;
if ! grep l2tp_ip /proc/modules > /dev/null; then
    modprobe l2tp_ip
fi;
if ! grep l2tp_ip6 /proc/modules > /dev/null; then
    modprobe l2tp_ip6
fi;
