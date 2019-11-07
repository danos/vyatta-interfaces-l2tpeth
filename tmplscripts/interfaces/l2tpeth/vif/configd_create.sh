#!/opt/vyatta/bin/cliexec
/opt/vyatta/sbin/vyatta-interfaces.pl --dev $VAR(../@) --create-vif $VAR(@)
/opt/vyatta/sbin/vyatta-link-detect "$VAR(../@).$VAR(@)" on
