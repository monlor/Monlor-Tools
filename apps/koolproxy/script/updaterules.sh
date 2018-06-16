#!/bin/ash
#copyright by monlor
monlorpath=$(uci -q get monlor.tools.path)
[ $? -eq 0 ] && source "$monlorpath"/scripts/base.sh || exit
eval `ucish export koolproxy`
adurl="https://raw.githubusercontent.com/kysdm/ad-rules/master/user-rules-koolproxy.txt"

logsh "【$service】" "更新用户自定义规则"
wgetsh $monlorpath/apps/$appname/bin/data/rules/user.txt $adurl
[ $? -ne 0 ] && logsh "【$service】" "更新用户自定义规则失败"