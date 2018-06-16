#!/bin/ash
#copyright by monlor
monlorpath=$(uci -q get monlor.tools.path) || exit 1
[ $? -eq 0 ] && source "$monlorpath"/scripts/base.sh || exit

appname=verysync
checkuci $appname && rm -rf /tmp/$appname/bin/$appname