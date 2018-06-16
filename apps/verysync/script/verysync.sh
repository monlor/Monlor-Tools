#!/bin/ash /etc/rc.common
monlorpath=$(uci -q get monlor.tools.path)
[ $? -eq 0 ] && source "$monlorpath"/scripts/base.sh || exit

START=95
STOP=95
SERVICE_USE_PID=1
SERVICE_WRITE_PID=1
SERVICE_DAEMONIZE=1

service=VerySync
appname=verysync
EXTRA_COMMANDS=" status backup recover"
EXTRA_HELP="        status  Get $appname status"
BIN=$monlorpath/apps/$appname/bin/$appname
CONF="$userdisk"/."$appname"
LOG=/var/log/$appname.log
port=$(uci -q get monlor.$appname.port) || port=8886
lanip=$(uci get network.lan.ipaddr)

start () {

	result=$(ps | grep $BIN | grep -v grep | wc -l)
   	if [ "$result" != '0' ];then
		logsh "【$service】" "$appname已经在运行！"
		exit 1
	fi
	logsh "【$service】" "正在启动$appname服务... "
	cru a "$appname" "0 6 * * * $monlorpath/apps/$appname/script/$appname.sh restart"
	[ -f "$BIN".old ] && rm -rf "$BIN".old
	# if [ ! -x "$BIN" ]; then
	# 	logsh "【$service】" "获取$appname二进制文件"
	# 	[ "$model" == "arm" ] && flag="verysync"
	# 	[ "$model" == "mips" ] && flag="verysync_mips"
	# 	wgetsh $monlorpath/apps/$appname/bin/$appname "$monlorurl"/temp/"$flag"
	# 	if [ $? -ne 0 ]; then
	# 		logsh "【$service】" "获取二进制文件失败！"
	# 		exit
	# 	fi
	# 	chmod +x $BIN
	# 	# $BIN -generate $userdisk > /tmp/messages 2>&1
	# fi
	[ ! -d "$CONF" ] && mkdir $CONF
	iptables -I INPUT -p tcp --dport $port -m comment --comment "monlor-$appname" -j ACCEPT 
	service_start $BIN -home "$CONF" -gui-address http://0.0.0.0:$port -no-browser -no-restart
	if [ $? -ne 0 ]; then
        logsh "【$service】" "启动$appname服务失败！"
		exit
	fi

	logsh "【$service】" "启动$appname服务完成！"
	logsh "【$service】" "请在浏览器中访问[http://$lanip:$port]"

}

stop () {

	logsh "【$service】" "正在停止$appname服务... "
	service_stop $BIN > /dev/null 2>&1
	ps | grep $BIN | grep -v grep | awk '{print$1}' | xargs kill -9 > /dev/null 2>&1
	iptables -D INPUT -p tcp --dport $port -m comment --comment "monlor-$appname" -j ACCEPT > /dev/null 2>&1
	logsh "【$service】" "卸载插件后可删除$CONF文件夹"
	[ "$enable" == '0' ] && destroy

}

destroy() {

	cru d "$appname"

}

restart () {

	stop
	sleep 1
	start

}

status() {

	result=$(pssh | grep $BIN | grep -v grep | wc -l)
	if [ "$result" -ne '0' ]; then
		echo "运行端口号: $port"
		echo "1"
	else
		echo "未运行"
		echo "0"
	fi

}

backup() {
	mkdir -p $monlorbackup/$appname
	cp -rf $CONF/*.pem $monlorbackup/$appname
	cp -rf $CONF/csrftokens.txt $monlorbackup/$appname
	cp -rf $CONF/setting.dat $monlorbackup/$appname
}

recover() {
	[ ! -d "$CONF" ] && mkdir -p $CONF
	cp -rf $monlorbackup/$appname/*.pem $CONF
	cp -rf $monlorbackup/$appname/csrftokens.txt $CONF
	cp -rf $monlorbackup/$appname/setting.dat $CONF
}