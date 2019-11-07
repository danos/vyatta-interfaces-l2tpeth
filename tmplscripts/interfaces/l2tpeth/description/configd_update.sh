#!/opt/vyatta/bin/cliexec
sh -c "echo \"$VAR(@)\" >/sys/class/net/$VAR(../@)/ifalias"
