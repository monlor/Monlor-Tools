#!/bin/ash /etc/rc.common
monlorpath=$(uci -q get monlor.tools.path)
[ $? -eq 0 ] && source "$monlorpath"/scripts/base.sh || exit

START=95
STOP=95
SERVICE_USE_PID=1
SERVICE_WRITE_PID=1
SERVICE_DAEMONIZE=1

eval `ucish export aria2`
EXTRA_COMMANDS=" status backup recover"
EXTRA_HELP="        status  Get $appname status"
port=6800
WEBDIR=$monlorpath/apps/$appname/web
[ -z "$port" ] && port=6800
[ -z "$path" ] && path="$userdisk/下载"
aria2url=http://$lanip/backup/log/$appname

set_config() {

	logsh "【$service】" "加载$appname配置..."
	[ ! -f /etc/aria2.session ] && touch /etc/aria2.session

	[ ! -z "$port" ] && sed -i "s/^.*rpc-listen-port.*$/rpc-listen-port=$port/" $CONF/$appname.conf

	if [ ! -z "$token" ]; then
		sed -i "s/^.*rpc-secret.*$/rpc-secret=$token/" $CONF/$appname.conf
	else
		sed -i "s/^.*rpc-secret.*$/#rpc-secret=/" $CONF/$appname.conf
	fi

	sed -i "s#dir.*#dir=$path#" $CONF/$appname.conf

	[ ! -d "$path" ] && mkdir -p $path

	#R3加载库文件
	[ "$xq" == "R3" -o "$xq" == "R1CM" ] && export LD_LIBRARY_PATH=$monlorpath/apps/$appname/lib:/usr/lib:/lib

	if [ ! -d /tmp/syslogbackup/$appname ]; then
		logsh "【$service】" "生成$appname本地web页面"
		mkdir -p /tmp/syslogbackup &> /dev/null
		ln -s $WEBDIR/AriaNG /tmp/syslogbackup/$appname > /dev/null 2>&1
	fi
	#添加定时重启任务
	cru a $appname "0 6 * * * $monlorpath/apps/$appname/script/$appname.sh restart"

}

start () {

	result=$(ps | grep $BIN/$appname | grep -v grep | wc -l)
    	if [ "$result" != '0' ];then
		logsh "【$service】" "$appname已经在运行！"
		exit 1
	fi
	logsh "【$service】" "正在启动$appname服务... "

	set_config
	
	iptables -I INPUT -p tcp --dport $port -m comment --comment "monlor-$appname" -j ACCEPT 
	service_start $BIN/$appname --conf-path=$CONF/$appname.conf -D -l $LOG/$appname.log
	if [ $? -ne 0 ]; then
        	logsh "【$service】" "启动$appname服务失败！"
		exit
	fi
	logsh "【$service】" "启动$appname服务完成！"
	logsh "【$service】" "访问[$aria2url]管理服务"
	[ -z "$token" ] && tokentext="" || tokentext=token:"$token"@
	logsh "【$service】" "jsonrpc地址:http://"$tokentext""$lanip":"$port"/jsonrpc"

}

stop () {

	logsh "【$service】" "正在停止$appname服务... "
	service_stop $BIN/$appname
	ps | grep $BIN/$appname | grep -v grep | awk '{print$1}' | xargs kill -9 > /dev/null 2>&1
	iptables -D INPUT -p tcp --dport $port -m comment --comment "monlor-$appname" -j ACCEPT > /dev/null 2>&1
	destroy
}

destroy() {
	if [ "$enable" == '0' ]; then
		[ -d /tmp/syslogbackup/$appname ] && rm -rf /tmp/syslogbackup/$appname
		cru d $appname
	fi
}

restart () {

	stop
	sleep 1
	start

}

status() {

	result=$(pssh | grep $BIN/$appname | grep -v grep | wc -l)
	if [ "$result" == '0' ]; then
		echo "未运行"
		echo "0"
	else
		echo "运行端口号: $port"
		echo "1"
	fi

}

backup() {

	mkdir -p $monlorbackup/$appname
	cp -rf $CONF/$appname.conf $monlorbackup/$appname/$appname.conf

}

recover() {

	cp -rf $monlorbackup/$appname/$appname.conf $CONF/$appname.conf

}