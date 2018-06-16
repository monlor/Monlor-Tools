#!/bin/ash /etc/rc.common
source "$(uci -q get monlor.tools.path)"/scripts/base.sh 
eval `ucish export filebrowser`

START=95
STOP=95
SERVICE_USE_PID=1
SERVICE_WRITE_PID=1
SERVICE_DAEMONIZE=1
EXTRA_COMMANDS=" status backup recover"
EXTRA_HELP="        status  Get $appname status"

[ -z "$port" ] && port=1086
[ -z "$scope" ] && scope="$userdisk"

start() {

        [ -n "$(pidof $appname)" ] && logsh "【$service】" "$appname已经在运行！" && exit 1
        logsh "【$service】" "正在启动$appname服务... "
        cru a "$appname" "0 6 * * * $monlorpath/apps/$appname/script/$appname.sh restart"
        # Scripts Here
        iptables -I INPUT -p tcp --dport $port -m comment --comment "monlor-$appname" -j ACCEPT 
        service_start $BIN/$appname -p $port -d $CONF/$appname.db -l $LOG/$appname.log -s $scope 
        [ $? -ne 0 ] && logsh "【$service】" "启动$appname服务失败！" && exit 1
        logsh "【$service】" "启动$appname服务完成！"
        logsh "【$service】" "请在浏览器中访问[http://$lanip:$port]，默认用户名密码admin"
        
}

stop() {

        logsh "【$service】" "正在停止$appname服务... "
        service_stop $BIN/$appname
        kill -9 "$(pidof $appname)"
        iptables -D INPUT -p tcp --dport $port -m comment --comment "monlor-$appname" -j ACCEPT > /dev/null 2>&1
        [ "$enable" == '0' ] && destroy

}

destroy() {
        
        # End app, Scripts here 
        cru d "$appname"
        return

}

restart() {

        stop 
        sleep 1
        start

}

status() {

        if [ -z "$(pidof $appname)" ]; then
                echo -e "未运行\n0"
        else
                echo -e "运行端口号：$port\n1"
        fi
}

backup() {

        mkdir -p $monlorbackup/$appname
        cp -rf $CONF/$appname.db $monlorbackup/$appname
        return

}

recover() {

        cp -rf $monlorbackup/$appname/$appname.db $CONF
        return

}
