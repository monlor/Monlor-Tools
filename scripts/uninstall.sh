#!/bin/ash
#copyright by monlor
source "$(uci -q get monlor.tools.path)"/scripts/base.sh 

clear
logsh "【Tools】" "即将卸载工具箱，按任意键继续(Ctrl + C 退出)."
read answer

logsh "【Tools】" "正在卸载工具箱..."

logsh "【Tools】" "停止所有插件"

ls $monlorpath/apps | while read line
do
	result=$(uci -q get monlor.$line.enable)
	[ "$result" == '1' ] && $monlorpath/apps/$line/script/$line.sh stop
done

logsh "【Tools】" "关闭工具箱web页面"
umount -lf /usr/lib/lua/luci
rm -rf /tmp/mountfiles
rm -rf /tmp/syslogbackup

logsh "【Tools】" "删除所有工具箱配置信息"

result=$(cat /etc/profile | grep -c monlor/config)
if [ "$result" != 0 ]; then
	sed -i "/monlor\/config/d" /etc/profile
fi

logsh "【Tools】" "删除定时任务"
cru c

result=$(cat /etc/firewall.user | grep init.sh | wc -l) > /dev/null 2>&1
if [ "$result" != '0' ]; then
	sed -i "/init.sh/d" /etc/firewall.user
fi

# if [ -f "$monlorconf" ]; then
# 	mv $monlorconf $userdisk/.monlor.conf.bak
# fi

xunlei_enable=$(uci -q get monlor.tools.xunlei)
if [ "$xunlei_enable" == '1' ]; then
	logsh "【Tools】" "检测到迅雷被关闭，正在恢复..."
	sed -i 's@/etc/thunder@/etc/config/thunder@g' /etc/init.d/xunlei
	if [ ! -d /etc/config/thunder ]; then
		cp -a  /etc/thunder /etc/config
		rm -rf /etc/thunder
	fi
	/etc/init.d/xunlei start &
fi
# 内存安装方式 取消挂载
ins_method=$(uci -q get monlor.tools.ins_method)
[ "$ins_method" == '0' ] && umount -lf $monlorpath/apps && rm -rf /tmp/monlorapps

if [ -f "/etc/config/monlor" ]; then
	rm -rf /etc/config/monlor
fi

logsh "【Tools】" "See You!"

rm -rf $monlorpath
