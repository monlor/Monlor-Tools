#!/bin/ash
#copyright by monlor
monlorpath=$(uci -q get monlor.tools.path)
[ $? -eq 0 ] && source "$monlorpath"/scripts/base.sh || exit

appname=shadowsocks
checkuci $appname && rm -rf /tmp/$appname/config/customize*.conf
if compare "$(uci -q get monlor.$appname.version)" "1.7.5"; then
	if checkuci $appname; then
		rm -rf /tmp/$appname/config/cdn.txt
		rm -rf /tmp/$appname/config/chnroute.txt
		rm -rf /tmp/$appname/config/gfwlist.conf
	fi
fi
[ -f $monlorpath/apps/$appname/config/chnroute.conf ] && rm -rf $monlorpath/apps/$appname/config/chnroute.conf