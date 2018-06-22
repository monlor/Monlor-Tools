#!/bin/ash /etc/rc.common
source "$(uci -q get monlor.tools.path)"/scripts/base.sh 
eval `ucish export zerotier`

START=95
STOP=95
SERVICE_USE_PID=1
SERVICE_WRITE_PID=1
SERVICE_DAEMONIZE=1
EXTRA_COMMANDS=" status backup recover"
EXTRA_HELP="        status  Get $appname status"
OPKG="/opt/bin/opkg"
ZTO="/opt/bin/zerotier-one"
ZTC="/opt/bin/zerotier-cli"

start() {

        [ -n "$(pidof "$appname"-one)" ] && logsh "【$service】" "$appname已经在运行！" && exit 1
        logsh "【$service】" "正在启动$appname服务... "
        cru a "$appname" "0 6 * * * $monlorpath/apps/$appname/script/$appname.sh restart"
        # Scripts Here
        [ -z "$networkid" ] && logsh "【$service】" "检测到未设置网络ID！关闭插件！" && end
        if [ "$(uci -q get monlor.entware.enable)" == '0' ]; then
                logsh "【$service】" "检测到Entware服务未启用或未安装！关闭插件！"
                end
        fi
        if [ -z "$($OPKG list-installed | grep $appname)" ]; then
                logsh "【$service】" "正在opkg安装$appname程序..."
                $OPKG install $appname
                [ $? -ne 0 ] && logsh "【$service】" "安装失败！请检查Entware环境！" && exit 1
        fi
        #添加entware识别
        sed -i "/$appname/d" $monlorpath/apps/entware/config/relyon.txt &> /dev/null
        echo "$appname" >> $monlorpath/apps/entware/config/relyon.txt
        # iptables -I INPUT -p tcp --dport $port -m comment --comment "monlor-$appname" -j ACCEPT 
        service_start $ZTO -d && sleep 1 && $ZTC join $networkid &> /dev/null
        [ $? -ne 0 ] && logsh "【$service】" "启动$appname服务失败！" && exit 1
        logsh "【$service】" "启动$appname服务完成！"
        
}

stop() {

        logsh "【$service】" "正在停止$appname服务... "
        service_stop $ZTO &> /dev/null
        kill -9 "$(pidof "$appname"-one)"
        # iptables -D INPUT -p tcp --dport $port -m comment --comment "monlor-$appname" -j ACCEPT > /dev/null 2>&1
        [ "$enable" == '0' ] && destroy

}

destroy() {
        
        # End app, Scripts here 
        cru d "$appname"
        #清除entware识别
        sed -i "/$appname/d" $monlorpath/apps/entware/config/relyon.txt 
        return

}

end() {

        uci set monlor.$appname.enable=0
        uci commit monlor
        stop
        exit 1

}

restart() {

        stop 
        sleep 1
        start

}

status() {

        ipaddr=$(ifconfig | grep -A8 ^zt | grep "inet addr" | awk '{print$2}' | cut -d':' -f2)
        if [ -n "$(pidof "$appname"-one)" ]; then
                port="$(cat /opt/var/lib/zerotier-one/zerotier-one.port)" &> /dev/null
                [ -n "$(echo $ipaddr | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}")" ] && iptext="，内网IP地址：$ipaddr" || iptext="，获取内网IP地址中"
                echo -e "运行端口号：$port$iptext\n1"
        else
                echo -e "未运行\n0"
        fi
}

backup() {

        mkdir -p $monlorbackup/$appname
        # Backup scripts here
        return

}

recover() {

        # Recover scripts here
        return

}
