#!/bin/ash /etc/rc.common
monlorpath=$(uci -q get monlor.tools.path)
[ $? -eq 0 ] && source "$monlorpath"/scripts/base.sh || exit

START=95
STOP=95
SERVICE_USE_PID=1
SERVICE_WRITE_PID=1
SERVICE_DAEMONIZE=1

eval `ucish export entware`
EXTRA_COMMANDS=" status backup recover"
EXTRA_HELP="        status  Get $appname status"
# port=
BIN=/opt/etc/init.d/rc.unslung
[ -z "$path" ] && path="$userdisk/.Entware"

init() {

	logsh "【$service】" "初始化$appname服务..."
	if [ -z "$path" ]; then 
		logsh "【$service】" "未配置安装路径！" 
		exit
	fi
	[ ! -f $BIN ] && mount -o blind $path /opt > /dev/null 2>&1
	[ -z "$profilepath" ] && logsh "【$service】" "工具箱环境变量出现问题！" && end
	result1=$(echo $profilepath | grep -c /opt/sbin)
	result2=$(echo $libpath | grep -c /opt/lib)
	[ "$result1" == '0' ] && uci -q set monlor.tools.profilepath="$profilepath:/opt/bin:/opt/sbin"
	[ "$result2" == '0' ] && uci -q set monlor.tools.libpath="$libpath:/opt/lib"
	uci commit monlor
	
	if [ ! -f $path/etc/init.d/rc.unslung ]; then
		logsh "【$service】" "检测到第一次运行$appname服务，正在安装..."
		mkdir -p $path > /dev/null 2>&1
		[ $? -ne 0 ] && logsh "【Tools】" "创建目录失败，检查你的路径是否正确！" && end
		umount -lf /opt > /dev/null 2>&1
		mount -o blind $path /opt
		if [ "$xq" == "R3D" ]; then
			wget -O - http://bin.entware.net/armv7sf-k3.2/installer/generic.sh | sh
		elif [ "$model" == "arm" ]; then
			wget -O - http://bin.entware.net/armv7sf-k2.6/installer/generic.sh | sh
		elif [ "$model" == "mips" ]; then
			wget -O - http://bin.entware.net/mipselsf-k3.4/installer/generic.sh | sh
		else
			logsh "【Tools】" "不支持你的路由器！"
			end
		fi
		if [ $? -ne 0 ]; then
			logsh "【Tools】" "【$appname】服务安装失败"
			umount -lf /opt
			rm -rf $path
			exit 1
		fi
		/opt/bin/opkg update
		source /etc/profile > /dev/null 2>&1
		logsh "【$service】" "安装完成，请运行source /etc/profile使配置生效!"
		logsh "【$service】" "如需安装ONMP，参考https://github.com/monlor/ONMP"
	fi
	# echo >> $monlorpath/config/profile
	if [ -z "$(cat $monlorpath/config/profile | grep "alias opkg")" ]; then
		echo "alias opkg=/opt/bin/opkg" >> $monlorpath/config/profile
		logsh "【$service】" "已修改opkg配置，请运行source /etc/profile生效！"
	fi
}

start () {

	result=$(ps | grep "{$appname}" | grep -v grep | wc -l)
    	if [ "$result" -gt '2' ];then
		logsh "【$service】" "$appname已经在运行！"
		exit 1
	fi
	logsh "【$service】" "正在启动$appname服务... "

	init
	
	# iptables -I INPUT -p tcp --dport $port -m comment --comment "monlor-$appname" -j ACCEPT 
	[ ! -f "$BIN" ] && sleep 2
	$BIN start >> /tmp/messages 2>&1
	if [ $? -ne 0 ]; then
 	     	logsh "【$service】" "启动$appname服务失败！"
	 	exit
	else
		logsh "【$service】" "$appname服务启动完成"
		if [ -f $CONF/relyon.txt ] && [ -n "$(cat $CONF/relyon.txt)" ]; then
			logsh "【$service】" "启动依赖$appname的所有插件..."
			cat $CONF/relyon.txt | while read line
			do
				[ -z "$line" ] && continue
				uci set monlor.$line.enable=1
				if [ "$($monlorpath/apps/$line/script/$line.sh status | tail -1)" == '0' ]; then
					$monlorpath/apps/$line/script/$line.sh restart
				fi
			done
			uci commit monlor
		fi
	fi

}

stop () {

	logsh "【$service】" "正在停止$appname服务... "
	[ "$enable" == '0' ] && destroy
	$BIN stop >> /tmp/messages 2>&1
	[ -f $BIN ] && umount -lf /opt
	# ps | grep $BIN | grep -v grep | awk '{print$1}' | xargs kill -9 > /dev/null 2>&1
	# iptables -D INPUT -p tcp --dport $port -m comment --comment "monlor-$appname" -j ACCEPT > /dev/null 2>&1
	logsh "【$service】" "停止成功，请运行source /etc/profile使配置生效!"
	logsh "【$service】" "若要重置【$appname】服务，删除$path文件并启动即可"

}

destroy() {
	if [ "$enable" == '0' ]; then
		logsh "【$service】" "关闭依赖$appname的所有插件..."
		if [ -f $CONF/relyon.txt ]; then
			cat $CONF/relyon.txt | while read line
			do
				[ -z "$line" ] && continue
				$monlorpath/apps/$line/script/$line.sh stop
				# 后将enable置为0不会运行destroy方法，保存依赖entware的插件列表
				uci set monlor.$line.enable=0
			done
		fi
		uci -q set monlor.tools.profilepath="`echo $profilepath | sed -e 's#:/opt/bin:/opt/sbin##g'`"
		uci -q set monlor.tools.libpath="`echo $libpath | sed -e 's#:/opt/lib##g'`"
		uci commit monlor
		sed -i "/alias opkg/d" $monlorpath/config/profile
		unalias opkg &> /dev/null
	fi
}

end() {

        uci set monlor.$appname.enable=0
        uci commit monlor
        stop
        exit 1

}

restart () {

	stop
	sleep 1
	start

}

status() {

	result1=$(echo $libpath | grep -c "/opt/lib")
	result2=$(echo $profilepath | grep -c /opt/sbin)
	if [ ! -f $BIN ] || [ -z $path ] || [ "$result1" == '0' ] || [ "$result2" == '0' ]; then
		echo "未运行"
		echo "0"
	else
		echo "安装路径: $path"
		echo "1"
	fi

}

backup() {

	mkdir -p $monlorbackup/$appname
	echo -n
}

recover() {

	echo -n
}