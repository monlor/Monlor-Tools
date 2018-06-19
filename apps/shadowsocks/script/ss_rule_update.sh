#!/bin/ash
#copyright by monlor
monlorpath=$(uci -q get monlor.tools.path)
[ $? -eq 0 ] && source "$monlorpath"/scripts/base.sh || exit
eval `ucish export shadowsocks`
chnroute=$CONF/chnroute.txt
gfwlist=$CONF/gfwlist.conf
cdnlist=$CONF/cdn.txt
url="https://koolshare.ngrok.wang/maintain_files"

logsh "【$service】" "更新$appname分流规则"
wgetsh $gfwlist $url/gfwlist.conf
[ $? -ne 0 ] && logsh "【$service】" "更新gfw黑名单规则失败"
wgetsh $chnroute $url/chnroute.txt
[ $? -ne 0 ] && logsh "【$service】" "更新大陆白名单规则失败"
wgetsh $cdnlist $url/cdn.txt
[ $? -ne 0 ] && logsh "【$service】" "更新cdn加速列表失败"

