#!/opt/vyatta/bin/cliexec
echo $VAR(@) >/sys/class/net/$VAR(../../@).$VAR(../@)/ifalias
