#!/bin/ash /etc/rc.common
monlorpath=$(uci -q get monlor.tools.path)
[ $? -eq 0 ] && source "$monlorpath"/scripts/base.sh || exit
eval `ucish export baidupcs`

START=95
STOP=95
SERVICE_USE_PID=1
SERVICE_WRITE_PID=1
SERVICE_DAEMONIZE=1
EXTRA_COMMANDS=" status backup recover"
EXTRA_HELP="        status  Get $appname status"

start() {

        [ -n "$(pidof $appname)" ] && logsh "【$service】" "$appname已经在运行！" && exit 1
        logsh "【$service】" "正在启动$appname服务... "
        # Scripts Here

        # iptables -I INPUT -p tcp --dport $port -m comment --comment "monlor-$appname" -j ACCEPT 
        service_start $BIN/$appname
        [ $? -ne 0 ] && logsh "【$service】" "启动$appname服务失败！" && exit 1
        logsh "【$service】" "启动$appname服务完成！"
        
}

stop() {

        logsh "【$service】" "正在停止$appname服务... "
        service_stop $BIN/$appname
        kill -9 "$(pidof $appname)"
        # iptables -D INPUT -p tcp --dport $port -m comment --comment "monlor-$appname" -j ACCEPT > /dev/null 2>&1

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
                echo -e "运行中\n1"
        fi
}

backup() {

        mkdir -p $monlorbackup/$appname
        echo -n

}

recover() {

        echo -n

}
