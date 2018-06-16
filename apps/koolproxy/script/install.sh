#!/bin/ash
#copyright by monlor
monlorpath=$(uci -q get monlor.tools.path)
[ $? -eq 0 ] && source "$monlorpath"/scripts/base.sh || exit

appname=koolproxy
openssl=$monlorpath/apps/$appname/bin/data/openssl
[ -f $openssl ] && rm -rf "$openssl"
[ -f "$openssl"_mips ] && rm -rf "$openssl"_mips
if checkuci $appname; then
	ver1="`/tmp/$appname/bin/$appname -v`"
	ver2="`$monlorpath/apps/$appname/bin/$appname -v`"
	compare $ver1 $ver2 || rm -rf /tmp/$appname/bin/$appname
	rm -rf /tmp/$appname/bin/data/rules/user.txt
fi