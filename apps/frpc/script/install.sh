#!/bin/ash
monlorpath=$(uci -q get monlor.tools.path)
[ $? -eq 0 ] && source "$monlorpath"/scripts/base.sh || exit

appname=frpc
uciname=info
frplist=$monlorpath/apps/$appname/config/frplist
if [ -f $frplist ]; then
	cat $frplist | while read line
	do
		name=$(echo $line | cutsh 1)
		type=$(echo $line | cutsh 2)
		localip=$(echo $line | cutsh 3)
		localport=$(echo $line | cutsh 4)
		remoteport=$(echo $line | cutsh 5)
		domain=$(echo $line | cutsh 6)
		ucish set $name "$type,$localip,$localport,$remoteport,$domain"
	done
	[ $? -eq 0 ] && rm -rf $frplist
fi