#!/bin/ash /etc/rc.common
monlorpath=$(uci -q get monlor.tools.path)
[ $? -eq 0 ] && source "$monlorpath"/scripts/base.sh || exit

START=95
STOP=95
SERVICE_USE_PID=1
SERVICE_WRITE_PID=1
SERVICE_DAEMONIZE=1

service=VsFtpd
appname=vsftpd
EXTRA_COMMANDS=" status backup recover"
EXTRA_HELP="        status  Get $appname status"
port=21
BIN=$monlorpath/apps/$appname/bin/$appname
CONF=$monlorpath/apps/$appname/config/$appname.conf
FTPUSER=$monlorpath/apps/$appname/config/ftpuser.conf
LOG=/var/log/$appname.log

add(){
	sed -i "/$1/"d /etc/passwd
	sed -i "/$1/"d /etc/shadow
	#if [ "$4" == '0' ]; then
	sshlogin=/bin/false;
	#else
	#	sshlogin=/bin/ash;
	#fi
	if [ ! -d "$3" ]; then 
		mkdir -p $3
	fi 
	echo "$1:*:10086:10086:$1:$3:$sshlogin" >> /etc/passwd
	echo "$1:*:0:0:99999:7:::" >> /etc/shadow
	echo -e "$2\n$2" | passwd $1 > /dev/null 2>&1

}
del(){
	sed -i "/^$1/"d /etc/passwd
	sed -i "/^$1/"d /etc/shadow
	sed -i "/^$1/"d /etc/vsftpd.users
}

set_config() {

	logsh "【$service】" "加载$appname设置... "

	[ ! -f $FTPUSER ] && logsh "【$service】" "未配置ftp用户！" && exit
	[ ! -f /etc/vsftpd.users ] && touch /etc/vsftpd.users
	cat /etc/vsftpd.users | while read line
	do
		[ ! -z "$line" ] && del $line
	done
	cat $FTPUSER | while read line
	do
		username=`cutsh $line 1`
		passwd=`cutsh $line 2`
		ftppath=`cutsh $line 3`
		echo $username >> /etc/vsftpd.users
		[ ! -z $username ] && add $username $passwd $ftppath
	done

	if [ `uci get monlor.$appname.anon_enable` = "1" ]; then
		anon_enable=YES
		anon_root=`uci get monlor.$appname.anon_root` || anon_root=/var/ftp 
		[ ! -d $anon_root ] && mkdir -p $anon_root
		[ ! -d $anon_root/Share ] && mkdir -p $anon_root/Share
		chmod 755 $anon_root
		dirmod=$(ls -ld $anon_root | cut -d' ' -f1)
		[ "$dirmod" == "drwxrwxrwx" ] && logsh "【$service】" "匿名访问开启失败，此目录不支持！"
		chmod 777 $anon_root/Share
		del ftp && add ftp 123 $anon_root
	else
		anon_enable=NO
	fi
	port=`uci get monlor.$appname.ftp_port` || port=21
	cp -rf $CONF /etc/vsftpd.conf
	[ ! -d /var/run/vsftpd ] && mkdir -p /var/run/vsftpd
	echo -e "anonymous_enable=$anon_enable\nanon_root=$anon_root\nlisten_port=$port" >> /etc/vsftpd.conf

}

start () {

	result=$(ps | grep $BIN | grep -v grep | wc -l)
    	if [ "$result" != '0' ];then
		logsh "【$service】" "$appname已经在运行！"
		exit 1
	fi
	logsh "【$service】" "正在启动$appname服务... "

	set_config
	
	iptables -I INPUT -p tcp --dport $port -m comment --comment "monlor-$appname" -j ACCEPT 
	service_start $BIN 
	if [ $? -ne 0 ]; then
        logsh "【$service】" "启动$appname服务失败！"
		exit
    fi
    logsh "【$service】" "启动$appname服务完成！"

}

stop () {

	logsh "【$service】" "正在停止$appname服务... "
	service_stop $BIN
	rm -rf /etc/vsftpd.conf
	ps | grep $BIN | grep -v grep | awk '{print$1}' | xargs kill -9 > /dev/null 2>&1
	iptables -D INPUT -p tcp --dport $port -m comment --comment "monlor-$appname" -j ACCEPT > /dev/null 2>&1

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
		echo "运行端口号: $port"
		echo "1"
	fi

}

backup() {

    mkdir -p $monlorbackup/$appname
    cp -rf $FTPUSER $monlorbackup/$appname/$appname.conf

}

recover() {

    cp -rf $monlorbackup/$appname/$appname.conf $FTPUSER

}