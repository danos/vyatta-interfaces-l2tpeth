#!/opt/vyatta/bin/cliexec
[ -d /sys/class/net/$VAR(../@).$VAR(@) ] || exit 0
ip link delete dev "$VAR(../@).$VAR(@)"
