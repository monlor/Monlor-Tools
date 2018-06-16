#!/bin/ash /etc/rc.common
monlorpath=$(uci -q get monlor.tools.path)
[ $? -eq 0 ] && source "$monlorpath"/scripts/base.sh || exit

START=95
STOP=95
SERVICE_USE_PID=1
SERVICE_WRITE_PID=1
SERVICE_DAEMONIZE=1

service=Ngrok
appname=ngrok
EXTRA_COMMANDS=" status backup recover"
EXTRA_HELP="        status  Get $appname status"
# port=
BIN=$monlorpath/apps/$appname/bin/$appname
CONF=$monlorpath/apps/$appname/config/ngroklist
LOG=/var/log/$appname.log
ser_host=$(uci -q get monlor.$appname.ser_host)
ser_port=$(uci -q get monlor.$appname.ser_port)

set_config() {

	local cmdstr=""
	ser_token=$(uci -q get monlor.$appname.ser_token)
	while read line
	do 
		[ `echo $line | grep -c "^#"` -ne 0 ] && continue 
		type=`echo $line | awk -F ',' '{print$2}'`
		lhost=`echo $line | awk -F ',' '{print$3}'`
		lport=`echo $line | awk -F ',' '{print$4}'`
		rport=`echo $line | awk -F ',' '{print$5}'`
		domain=`echo $line | awk -F ',' '{print$6}'`
		if [ "$type" == "tcp" ]; then
			cmdstr="$cmdstr -AddTun[Type:$type,Lhost:$lhost,Lport:$lport,Rport:$rport]"
		else
			if [ `echo $domain | grep "\." | wc -l` -ne 0 ]; then
				cmdstr="$cmdstr -AddTun[Type:$type,Lhost:$lhost,Lport:$lport,Hostname:$domain]" 
			else
				cmdstr="$cmdstr -AddTun[Type:$type,Lhost:$lhost,Lport:$lport,Sdname:$domain]" 
			fi
		fi
	done < $CONF
	[ -z "$cmdstr" ] || cmdstr="$BIN -SER[Shost:$ser_host,Sport:$ser_port,Password:$ser_token]$cmdstr"
	echo $cmdstr

}

start () {

	result=$(ps | grep $BIN | grep -v grep | wc -l)
    	if [ "$result" != '0' ];then
		logsh "【$service】" "$appname已经在运行！"
		exit 1
	fi
	logsh "【$service】" "正在启动$appname服务... "
	[ -z "$ser_host" -o -z "$ser_port" ] && logsh "【$service】" "$appname未配置" && exit
	runstr=`set_config`
	# iptables -I INPUT -p tcp --dport $port -m comment --comment "monlor-$appname" -j ACCEPT 
	service_start $runstr
	if [ $? -ne 0 ]; then
        logsh "【$service】" "启动$appname服务失败！"
		exit
    fi
    logsh "【$service】" "启动$appname服务完成！"

}

stop () {

	logsh "【$service】" "正在停止$appname服务... "
	service_stop $BIN
	ps | grep $BIN | grep -v grep | awk '{print$1}' | xargs kill -9 > /dev/null 2>&1
	# iptables -D INPUT -p tcp --dport $port -m comment --comment "monlor-$appname" -j ACCEPT > /dev/null 2>&1

}

restart () {

	stop
	sleep 1
	start

}

status() {

	result=$(pssh | grep $BIN | grep -v grep | wc -l)
	if [ "$result" == '0' ]; then
		echo "未运行"
		echo "0"
	else
		echo "运行服务器: $ser_host:$ser_port"
		echo "1"
	fi

}

backup() {

	mkdir -p $monlorbackup/$appname
	cp -rf $CONF $monlorbackup/$appname/$appname.conf

}

recover() {

	cp -rf $monlorbackup/$appname/$appname.conf $CONF

}