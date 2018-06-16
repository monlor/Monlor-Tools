#!/bin/ash
#copyright by monlor
source "$(uci -q get monlor.tools.path)"/scripts/base.sh 
logsh "【Tools】" "工具箱监测脚本启动..." -p
[ ! -d "$monlorpath" ] && logsh "【Tools】" "工具箱文件未找到，请确认是否拔出外接设备！" && exit
result=$(ps | grep {monitor.sh} | grep -v grep | wc -l)
[ "$result" -gt '3' ] && logsh "【Tools】" "检测到monitor.sh已在运行" && exit
[ -n "$(pidof monlor)" -a "$1" != '-f' ] && logsh "【Tools】" "检测到正在配置工具箱！" && exit
[ -n "$(pidof update.sh)" ] && logsh "【Tools】" "检测到工具箱正在更新！" && exit

#检查samba共享目录
samba_path=$(uci -q get monlor.tools.samba_path)
if [ ! -z "$samba_path" ]; then
	logsh "【Tools】" "检查samba共享目录配置" -s
	if [ ! -f /etc/samba/smb.conf ]; then
		logsh "【Tools】" "未找到samba配置文件！" 
	else
		result=$(cat /etc/samba/smb.conf | grep path | head -1 | awk '{print$3}')
		if [ "$result" != "$samba_path" ]; then
			logsh "【Tools】" "检测到samba路径变更, 正在设置..."
			sed -i "1,/path/ s#\(path\).*#\1 = $samba_path#" /etc/samba/smb.conf
			killall smbd && /usr/sbin/smbd -D &> /dev/null
			killall nmbd && /usr/sbin/nmbd -D &> /dev/null
		fi
	fi
fi

#检查外接盘变化
if [ "$model" == "mips" -a "$(uci -q get monlor.tools.ins_method)" == '2' ]; then
	logsh "【Tools】" "检查外置储存状态..." -s
	userdisk2=$(df|awk '/\/extdisks\/sd[a-z][0-9]?$/{print $6;exit}')
	if [ ! -z "$userdisk2" ]; then
		if [ "$userdisk" != "$userdisk2" ]; then
			userdisk="$userdisk2"
			uci set monlor.tools.userdisk="$userdisk"
			uci commit monlor
		fi
	else
		userdisk="$monlorpath"
		uci set monlor.tools.userdisk="$userdisk"
		uci commit monlor
	fi
fi

# 检查CPU占用100%问题
logsh "【Tools】" "检查系统进程CPU占用" -s
top -n1 -b > /tmp/toptmp.txt
toptext=$(cat /tmp/toptmp.txt | grep ustackd | grep -v grep | head -1)
if [ ! -z "$toptext" ]; then
	result=$(echo $toptext | awk '{print$9}')
	[ -z $(echo $result | grep "^[0-9][0-9]*$") ] && result=$(echo $toptext | awk '{print$8}') 
	if [ ! -z "$result" ]; then
		result=$(echo $result | cut -d. -f1)
		[ "$result" -gt "20" ] && killall ustackd > /dev/null 2>&1
	fi
fi

toptext=$(cat /tmp/toptmp.txt | grep himan | grep -v grep | head -1)
if [ ! -z "$toptext" ]; then
	result=$(echo $toptext | awk '{print$9}')
	[ -z $(echo $result | grep "^[0-9][0-9]*$") ] && result=$(echo $toptext | awk '{print$8}') 
	if [ ! -z "$result" ]; then
		result=$(echo $result | cut -d. -f1)
		[ "$result" -gt "20" ] && killall himan > /dev/null 2>&1
	fi
fi

monitor() {
	appname=$1
	checkuci $appname || return
	service=`uci -q get monlor.$1.service` || service="$appname"
	if [ -z $appname ] || [ -z $service ]; then
		logsh "【Tools】" "未传入插件名！"
		return
	fi
	App_enable=$(uci -q get monlor.$appname.enable) 
	result=$($monlorpath/apps/$appname/script/$appname.sh status | tail -1) 
	
	#检查插件运行异常情况
	if [ -z "$(pidof $appname.sh)" ]; then
		if [ "$App_enable" == '1' -a "$result" == '0' ]; then
			logsh "【$service】" "$appname运行异常，正在重启..." 
			$monlorpath/apps/$appname/script/$appname.sh restart 
		# elif [ "$App_enable" == '0' -a "$result" == '1' ]; then
		# 	logsh "【$service】" "$appname配置已修改，正在停止$appname服务..."   
		# 	$monlorpath/apps/$appname/script/$appname.sh stop
		fi
	fi

}

#监控运行状态
logsh "【Tools】" "检查插件运行状态" -s
cat $monlorpath/config/applist.txt | while read line
do
	monitor $line
done

# logger -s -t "【Tools】" "获取更新插件列表"
# rm -rf /tmp/applist.txt
# wgetsh /tmp/applist.txt $monlorurl/temp/applist_"$xq".txt
# if [ $? -ne 0 ]; then
# 	[ "$model" == "arm" ] && applist="applist.txt"
# 	[ "$model" == "mips" ] && applist="applist_mips.txt"
# 	wgetsh /tmp/applist.txt $monlorurl/temp/"$applist"
# 	[ $? -ne 0 ] && logsh "【Tools】" "获取失败，检查网络问题！"
# fi
# logger -s -t "【Tools】" "获取工具箱版本信息"
# rm -rf /tmp/version
# rm -rf /tmp/version.tar.gz
# wgetsh /tmp/version.tar.gz $monlorurl/version.tar.gz
# [ $? -ne 0 ] && logsh "【Tools】" "获取版本号信息失败！请稍后再试"
# tar -zxvf /tmp/version.tar.gz -C /tmp > /dev/null 2>&1
# rm -rf /tmp/version.tar.gz

# ssh登陆界面
# $monlorpath/scripts/monlor menulist > /tmp/banner