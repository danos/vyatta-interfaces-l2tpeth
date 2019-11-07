#!/opt/vyatta/bin/cliexec
sh -c "echo '' >/sys/class/net/$VAR(../@)/ifalias"
