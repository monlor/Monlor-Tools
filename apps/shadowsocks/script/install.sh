#!/bin/ash
#copyright by monlor
monlorpath=$(uci -q get monlor.tools.path)
[ $? -eq 0 ] && source "$monlorpath"/scripts/base.sh || exit

appname=shadowsocks
checkuci $appname && rm -rf /tmp/$appname/config/customize*.conf