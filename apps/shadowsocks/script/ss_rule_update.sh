#!/bin/ash
#copyright by monlor
monlorpath=$(uci -q get monlor.tools.path)
[ $? -eq 0 ] && source "$monlorpath"/scripts/base.sh || exit
eval `ucish export shadowsocks`
chnroute=$CONF/chnroute.conf
gfwlist=$CONF/gfwlist.conf
cdnlist=$CONF/cdn.txt

logsh "【$service】" "更新$appname分流规则"
wgetsh $gfwlist https://cokebar.github.io/gfwlist2dnsmasq/gfwlist_domain.txt
[ $? -ne 0 ] && logsh "【$service】" "更新gfw黑名单规则失败"
wgetsh $chnroute https://raw.githubusercontent.com/17mon/china_ip_list/master/china_ip_list.txt
[ $? -ne 0 ] && logsh "【$service】" "更新大陆白名单规则失败"
wgetsh $cdnlist https://koolshare.ngrok.wang/maintain_files/cdn.txt
[ $? -ne 0 ] && logsh "【$service】" "更新cdn加速列表失败"

