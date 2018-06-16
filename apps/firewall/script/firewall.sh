#!/bin/ash /etc/rc.common
monlorpath=$(uci -q get monlor.tools.path)
[ $? -eq 0 ] && source "$monlorpath"/scripts/base.sh || exit

START=95
STOP=95
SERVICE_USE_PID=1
SERVICE_WRITE_PID=1
SERVICE_DAEMONIZE=1

service=FireWall
appname=firewall
uciname=openport
EXTRA_COMMANDS=" status backup recover"
EXTRA_HELP="        status  Get $appname status"
# port=1688
BIN=$monlorpath/apps/$appname/bin/$appname
CONF=$monlorpath/apps/$appname/config/$appname.conf
LOG=/var/log/$appname.log

set_config() {

	logsh "【$service】" "加载$appname配置"
	[ -z "`ucish keys`" ] && logsh "【$service】" "未添加$appname配置！" && exit
	ucish keys | while read line
	do
		name="$line"
		port=$(ucish get $name)
		[ -z "$name" -o -z "$port" ] && return 1
		logsh "【$service】" "开放$name的端口号: $port"
		iptables -I INPUT -p tcp --dport "$port" -m comment --comment "$appname"-"$name" -j ACCEPT > /dev/null 2>&1
	done
	return 0
}

start () {

	result=$(ps | grep $BIN | grep -v grep | wc -l)
    	if [ "$result" != '0' ];then
		logsh "【$service】" "$appname已经在运行！"
		exit 1
	fi
	logsh "【$service】" "正在启动$appname服务... "

	set_config
	
	# iptables -I INPUT -p tcp --dport $port -m comment --comment "monlor-$appname" -j ACCEPT 
	if [ $? -eq 0 ]; then
       	logsh "【$service】" "启动$appname服务完成！"
	else
		logsh "【$service】" "开放端口失败，配置出现问题！"
		logsh "【$service】" "启动$appname服务失败！"
		exit
    fi
    

}

stop () {

	logsh "【$service】" "正在停止$appname服务... "
	# iptables -D INPUT -p tcp --dport $port -m comment --comment "monlor-$appname" -j ACCEPT > /dev/null 2>&1
	iptables -S | grep "$appname"- | sed -e 's/-A/iptables -D/g' > /tmp/clean.sh 
	chmod +x /tmp/clean.sh
	/tmp/clean.sh
	rm -rf /tmp/clean.sh

}

restart () {

	stop
	sleep 1
	start

}

status() {

	result=$(iptables -S | grep -c "$appname"-)
	if [ "$result" != '0' ]; then
		echo "运行中"
		echo "1"
	else
		echo "未运行"
		echo "0"
	fi

}

backup() {
	
	mkdir -p $monlorbackup/$appname
	echo -n
}

recover() {
	echo -n
}