#!/bin/sh
# 快速生成新app
dir=./apps
appname="$1"
service="$2"
appinfo="$3"
tools="$(cat config/version.txt)"
[ -z "$appname" -o -z "$service" -o -z "$appinfo" ] && echo "信息为空(插件名，服务名，介绍)！" && exit
[ -d $dir/$appname ] && echo "插件已存在！" && exit
cd $dir || (mkdir -p $dir && cd $dir)
mkdir -p $appname
mkdir -p $appname/bin
mkdir -p $appname/config
mkdir -p $appname/script
echo "生成插件版本号文件..."
echo 1.0.0 > $appname/config/version.txt
echo "生成插件uci配置文件..."
cat > $appname/config/$appname.uci <<-EOF
uciset="uci set monlor.$appname"
\$uciset=config
\$uciset.service="$service"
\$uciset.appname="$appname"
\$uciset.tools="$tools"
\$uciset.appinfo="$appinfo"
\$uciset.newinfo=""
EOF
echo "生成工具箱配置文件..."
cat > $appname/config/monlor.conf <<EOF
#------------------【$2】--------------------
$appname() {

        eval \`ucish export $appname\`
        uciset="uci set monlor.\$appname"
        echo "********* \$service ***********"
        echo "[\$appinfo]"
        read -p "启动\$appname服务？[1/0] " enable
        checkread \$enable && \$uciset.enable="\$enable"
        if [ "\$enable" == '1' ]; then
                # Scripts Here

                \$monlorpath/apps/\$appname/script/\$appname.sh restart
        else
                \$monlorpath/apps/\$appname/script/\$appname.sh stop
        fi

}
#------------------【$2】--------------------
EOF
echo "生成插件运行脚本..."
cat > $appname/script/$appname.sh <<-EOF
#!/bin/ash /etc/rc.common
source "\$(uci -q get monlor.tools.path)"/scripts/base.sh 
eval \`ucish export $appname\`

START=95
STOP=95
SERVICE_USE_PID=1
SERVICE_WRITE_PID=1
SERVICE_DAEMONIZE=1
EXTRA_COMMANDS=" status backup recover"
EXTRA_HELP="        status  Get \$appname status"

start() {

        [ -n "\$(pidof \$appname)" ] && logsh "【\$service】" "\$appname已经在运行！" && exit 1
        logsh "【\$service】" "正在启动\$appname服务... "
        # cru a "\$appname" "0 6 * * * \$monlorpath/apps/\$appname/script/\$appname.sh restart"
        # Scripts Here
        # iptables -I INPUT -p tcp --dport \$port -m comment --comment "monlor-\$appname" -j ACCEPT 
        service_start \$BIN/\$appname
        [ \$? -ne 0 ] && logsh "【\$service】" "启动\$appname服务失败！" && end
        logsh "【\$service】" "启动\$appname服务完成！"
        
}

stop() {

        logsh "【\$service】" "正在停止\$appname服务... "
        [ "\$enable" == '0' ] && destroy
        service_stop \$BIN/\$appname
        kill -9 "\$(pidof \$appname)"
        # iptables -D INPUT -p tcp --dport \$port -m comment --comment "monlor-\$appname" -j ACCEPT > /dev/null 2>&1

}

destroy() {
        
        # End app, Scripts here 
        # cru d "\$appname"
        return

}

end() {

        stop
        uci set monlor.\$appname.enable=0
        uci commit monlor
        exit 1

}

restart() {

        stop 
        sleep 1
        start

}

status() {

        if [ -n "\$(pidof \$appname)" ]; then
                echo -e "运行中\n1"
        else
                echo -e "未运行\n0"
        fi
}

backup() {

        mkdir -p \$monlorbackup/\$appname
        # Backup scripts here
        return

}

recover() {

        # Recover scripts here
        return

}
EOF
