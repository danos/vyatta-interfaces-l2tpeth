#!/opt/vyatta/bin/cliexec
! cli-shell-api exists interfaces l2tpeth $VAR(@) l2tp-session || /opt/vyatta/sbin/vyatta-intf-end $VAR(@)
