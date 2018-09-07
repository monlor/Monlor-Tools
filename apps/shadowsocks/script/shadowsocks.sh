#!/bin/ash /etc/rc.common
source "$(uci -q get monlor.tools.path)"/scripts/base.sh 

START=95
SERVICE_USE_PID=1
SERVICE_WRITE_PID=1
SERVICE_DAEMONIZE=1

eval `ucish export shadowsocks`
EXTRA_COMMANDS=" status backup recover"
EXTRA_HELP="        status  Get $appname status"
[ -z "$CDN" ] && CDN=223.5.5.5
[ -z "$DNS_SERVER" ] && DNS_SERVER=8.8.8.8
[ -z "$DNS_SERVER_PORT" ] && DNS_SERVER_PORT=53
[ -z "$ss_proxy_default_mode" ] && ss_proxy_default_mode=1
[ -z "$ss_game_default_mode" ] && ss_game_default_mode=0
[ -z "$dns_red_ip" ] && dns_red_ip="$lanip"

get_config() {
    
	logsh "【$service】" "创建ss节点配置文件..."
	[ -z "$id" ] && logsh "【$service】" "未配置$appname运行节点！" && exit
	local_ip=0.0.0.0
	idinfo=`cat $CONF/ssserver* | grep "$id" | head -1`
	[ -z "$idinfo" ] && logsh "【$service】" "未找到ss节点：$id" && exit
	ss_name=`cutsh "$idinfo" 1`
	ss_server=`cutsh "$idinfo" 2`
	ss_server_port=`cutsh "$idinfo" 3`
	ss_password=`cutsh "$idinfo" 4`
	ss_method=`cutsh "$idinfo" 5`
	ssr_protocol=`cutsh "$idinfo" 6`
	ssr_obfs=`cutsh "$idinfo" 7`
	ssr_protocol_param=`cutsh "$idinfo" 8`
	ssr_obfs_param=`cutsh "$idinfo" 9`
	IFIP=`echo $ss_server | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
	if [ -z "$IFIP" ]; then
		ss_server_tmp=`resolveip $ss_server | head -1` 
		[ $? -ne 0 ] && logsh "【$service】" "ss服务器地址解析失败，跳过解析！" || ss_server="$ss_server_tmp"
   	fi
	#生成配置文件
	if [ -z "$ssr_protocol" -o -z "$ssr_obfs" ]; then
		APPPATH=$BIN/ss-redir
		LOCALPATH=$BIN/ss-local
		cat > $CONF/ss.conf <<-EOF
			{
			    "server":"$ss_server",
			    "server_port":$ss_server_port,
			    "local_address":"0.0.0.0",
			    "local_port":1081,
			    "password":"$ss_password",
			    "timeout":600,
			    "method":"$ss_method"
			}
		EOF
	else
		APPPATH=$BIN/ssr-redir
		LOCALPATH=$BIN/ssr-local
		cat > $CONF/ss.conf <<-EOF
			{
			    "server":"$ss_server",
			    "server_port":$ss_server_port,
			    "local_address":"0.0.0.0",
			    "local_port":1081,
			    "password":"$ss_password",
			    "timeout":600,
			    "protocol":"$ssr_protocol",
			    "protocol_param":"$ssr_protocol_param",
			    "obfs":"$ssr_obfs",
			    "obfs_param":"$ssr_obfs_param",
			    "method":"$ss_method"
			}
		EOF
	fi
	cp $CONF/ss.conf $CONF/dns2socks.conf && sed -i 's/1081/1082/g' $CONF/dns2socks.conf
	#用户生成ss连接日志
	$APPPATH -b 0.0.0.0 -u -c $CONF/ss.conf &> $LOG/$appname.log &
	if [ "$ssgena" == '1' -a "$ssgid" != "$id" ]; then
		[ -z "$ssgid" ] && logsh "【$service】" "未配置$appname游戏运行节点！" && exit
		idinfo=`cat $CONF/ssserver* | grep "$ssgid" | head -1`
	    	[ -z "$idinfo" ] && logsh "【$service】" "未找到ss节点：$ssgid" && exit
	    	ssg_name=`cutsh "$idinfo" 1`
	    	ssg_server=`cutsh "$idinfo" 2`
	    	ssg_server_port=`cutsh "$idinfo" 3`
	    	ssg_password=`cutsh "$idinfo" 4`
	    	ssg_method=`cutsh "$idinfo" 5`
	    	ssg_protocol=`cutsh "$idinfo" 6`
		ssg_obfs=`cutsh "$idinfo" 7`
		ssg_protocol_param=`cutsh "$idinfo" 8`
		ssg_obfs_param=`cutsh "$idinfo" 9`
		IFIP=`echo $ssg_server | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
		if [ -z "$IFIP" ]; then
			ssg_server_tmp=`resolveip $ssg_server | head -1` 
			[ $? -ne 0 ] && logsh "【$service】" "ss游戏服务器地址解析失败，跳过解析！" || ssg_server="$ssg_server_tmp"
	   	fi
		if [ -z "$ssg_protocol" -o -z "$ssg_obfs" ]; then
			cp -rf $BIN/ss-redir $BIN/ssg-redir
			cat > $CONF/ssg.conf <<-EOF
				{
				    "server":"$ssg_server",
				    "server_port":$ssg_server_port,
				    "local_address":"0.0.0.0",
				    "local_port":1085,
				    "password":"$ssg_password",
				    "timeout":600,
				    "method":"$ssg_method"
				}
			EOF
		else
			cp -rf $BIN/ssr-redir $BIN/ssg-redir
			cat > $CONF/ssg.conf <<-EOF
				{
				    "server":"$ssg_server",
				    "server_port":$ssg_server_port,
				    "local_address":"0.0.0.0",
				    "local_port":1085,
				    "password":"$ssg_password",
				    "timeout":600,
				    "protocol":"$ssg_protocol",
				    "protocol_param":"$ssg_protocol_param",
				    "obfs":"$ssg_obfs",
				    "obfs_param":"$ssg_obfs_param",
				    "method":"$ssg_method"
				}
			EOF
		fi
	fi

}

dnsconfig() {

	insmod ipt_REDIRECT 2>/dev/null
	service_start $LOCALPATH -c $CONF/dns2socks.conf
	killall dns2socks > /dev/null 2>&1
	logsh "【$service】" "开启dns2socks进程..."
	service_start $BIN/dns2socks 127.0.0.1:1082 $DNS_SERVER:$DNS_SERVER_PORT 127.0.0.1:15353 
	if [ $? -ne 0 ]; then
	    	logsh "【$service】" "启动失败！"
	    	exit
	fi
	if [ "$dns_red_enable" == '1' ]; then
		logsh "【$service】" "启用DNS重定向到$dns_red_ip"
		iptables -t nat -I PREROUTING -s $lanip/24 -p udp --dport 53 -m comment --comment "$appname"-dns -j DNAT --to $dns_red_ip &> /dev/null
	fi
     
}

get_mode_name() {
	case "$1" in
		0)
			echo "不走代理"
		;;
		1)
			echo "科学上网"
		;;
	esac
}

get_game_mode() {
	case "$1" in
		0)
			echo "不走游戏"
		;;
		1)
			echo "游戏加速"
		;;
	esac
}

get_jump_mode(){
	case "$1" in
		0)
			echo "-j"
		;;
		*)
			echo "-g"
		;;
	esac
}

get_action_chain() {
	case "$1" in
		0)
			echo "RETURN"
		;;
		1)
			echo "SHADOWSOCK"
		;;
	esac
}

load_nat() {

	logsh "【$service】" "加载iptables的nat规则..."
	iptables -t nat -N SHADOWSOCKS
	iptables -t nat -N SHADOWSOCK
	iptables -t nat -A SHADOWSOCKS -d 0.0.0.0/8 -j RETURN
	iptables -t nat -A SHADOWSOCKS -d $lanip/24 -j RETURN
	iptables -t nat -A SHADOWSOCKS -d $wanip/16 -j RETURN
	iptables -t nat -A SHADOWSOCKS -d $ss_server -j RETURN
	[ "$ssgena" == '1' -a "$ssgid" != "$id" ] && iptables -t nat -A SHADOWSOCKS -d $ssg_server -j RETURN 

	if [ "$ssgena" == '1' ]; then
		logsh "【$service】" "添加iptables的udp规则..."
		ip rule add fwmark 0x01/0x01 table 300
		ip route add local 0.0.0.0/0 dev lo table 300
		iptables -t mangle -N SHADOWSOCKS
		iptables -t mangle -N SHADOWSOCK
		iptables -t mangle -A SHADOWSOCKS -d 0.0.0.0/8 -j RETURN
		iptables -t mangle -A SHADOWSOCKS -d 127.0.0.1/16 -j RETURN
		iptables -t mangle -A SHADOWSOCKS -d $lanip/16 -j RETURN
		iptables -t mangle -A SHADOWSOCKS -d $wanip/16 -j RETURN
		iptables -t mangle -A SHADOWSOCKS -d $ss_server -j RETURN
		[ "$ssgid" != "$id" ] && iptables -t mangle -A SHADOWSOCKS -d $ssg_server -j RETURN

		chmod -x /opt/filetunnel/stunserver > /dev/null 2>&1
		killall -9 stunserver > /dev/null 2>&1
	fi
	#lan access control
	[ ! -f $CONF/sscontrol.conf ] && touch $CONF/sscontrol.conf
	cat $CONF/sscontrol.conf | while read line
	do
		mac=$(cutsh $line 2)
		proxy_name=$(cutsh $line 1)
		proxy_mode=$(cutsh $line 3)
		game_mode=$(cutsh $line 4)
		[ -z "$game_mode" ] && game_mode="$proxy_mode"		
		iptables -t nat -A SHADOWSOCKS -m mac --mac-source $mac $(get_jump_mode $proxy_mode) $(get_action_chain $proxy_mode)
		if [ "$ssgena" == '1' ]; then
			iptables -t mangle -A SHADOWSOCKS -m mac --mac-source $mac $(get_jump_mode $game_mode) $(get_action_chain $game_mode)
			args="[$(get_game_mode $game_mode)]"
		else
			args=""
		fi
		logsh "【$service】" "加载ACL规则:[$proxy_name]代理模式为:[$(get_mode_name $proxy_mode)]$args"
	done
	#default alc mode
	result=$(cat $CONF/sscontrol.conf | wc -l)
	[ "$result" == '0' ] && flag="全部主机" || flag="其余主机"
	[ "$ssgena" == '1' ] && args="[$(get_game_mode $ss_game_default_mode)]" || args=""
	logsh "【$service】" "加载ACL规则:[$flag]代理模式为:[$(get_mode_name $ss_proxy_default_mode)]$args"
	iptables -t nat -A SHADOWSOCKS -p tcp -j $(get_action_chain $ss_proxy_default_mode)
	[ "$ssgena" == '1' ] && iptables -t mangle -A SHADOWSOCKS -p udp -j $(get_action_chain $ss_game_default_mode)
	[ ! -f $CONF/customize_black.conf ] && touch $CONF/customize_black.conf
	[ ! -f $CONF/customize_white.conf ] && touch $CONF/customize_white.conf
	rm -rf /tmp/wblist.conf
	rm -rf /tmp/sscdn.conf
	ipset -N customize_black iphash -!  
	ipset -N customize_white iphash -!
	ipset -N router iphash -!
	# 生成黑名单规则
	cat $CONF/customize_black.conf | sed -E '/^$|^[#;]/d' | while read line                                                                   
	do         
		if [ -z "$(echo $line | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}")" ]; then                                                                                
			echo "server=/.$line/127.0.0.1#15353" >> /tmp/wblist.conf  
			echo "ipset=/.$line/customize_black" >> /tmp/wblist.conf  
		else
			ipset -! add customize_black $line &> /dev/null
		fi                   
	done
	ip_tg="149.154.0.0/16 91.108.4.0/22 91.108.56.0/24 109.239.140.0/24 67.198.55.0/24"
	for ip in $ip_tg
	do
		ipset -! add customize_black $ip >/dev/null 2>&1
	done
	# 路由器自身规则
	if [ "$ss_mode" != "homemode" ]; then
		echo "#for router itself" >> /tmp/wblist.conf
		echo "server=/.google.com.tw/127.0.0.1#15353" >> /tmp/wblist.conf
		echo "ipset=/.google.com.tw/router" >> /tmp/wblist.conf
		echo "server=/dns.google.com/127.0.0.1#15353" >> /tmp/wblist.conf
		echo "ipset=/dns.google.com/router" >> /tmp/wblist.conf
		echo "server=/.github.com/127.0.0.1#15353" >> /tmp/wblist.conf
		echo "ipset=/.github.com/router" >> /tmp/wblist.conf
		echo "server=/.github.io/127.0.0.1#15353" >> /tmp/wblist.conf
		echo "ipset=/.github.io/router" >> /tmp/wblist.conf
		echo "server=/.raw.githubusercontent.com/127.0.0.1#15353" >> /tmp/wblist.conf
		echo "ipset=/.raw.githubusercontent.com/router" >> /tmp/wblist.conf
		echo "server=/.adblockplus.org/127.0.0.1#15353" >> /tmp/wblist.conf
		echo "ipset=/.adblockplus.org/router" >> /tmp/wblist.conf
		echo "server=/.entware.net/127.0.0.1#15353" >> /tmp/wblist.conf
		echo "ipset=/.entware.net/router" >> /tmp/wblist.conf
		echo "server=/.apnic.net/127.0.0.1#15353" >> /tmp/wblist.conf
		echo "ipset=/.apnic.net/router" >> /tmp/wblist.conf
	fi
	# 生成白名单规则
	cat $CONF/customize_white.conf | sed -E '/^$|^[#;]/d' | while read line
	do
		if [ -z "$(echo $line | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}")" ]; then
			echo "server=/.$line/$CDN#53" >> /tmp/wblist.conf
			echo "ipset=/.$line/customize_white" >> /tmp/wblist.conf
		else
			ipset -! add customize_white $line &> /dev/null
		fi
	done 
	echo "server=/.apple.com/$CDN#53" >> /tmp/wblist.conf
	echo "ipset=/.apple.com/customize_white" >> /tmp/wblist.conf
	echo "server=/.microsoft.com/$CDN#53" >> /tmp/wblist.conf
	echo "ipset=/.microsoft.com/customize_white" >> /tmp/wblist.conf
	#加速cdn
	if [ "$ss_mode" != "gfwlist" ]; then
		cat $CONF/cdn.txt | sed "s/^/server=&\/./g" | sed "s/$/\/&$CDN/g" | sort | awk '{if ($0!=line) print;line=$0}' >>/tmp/sscdn.conf
		ln -s /tmp/sscdn.conf /etc/dnsmasq.d/cdn.conf
	fi
	# 使规则生效
	ln -s /tmp/wblist.conf /etc/dnsmasq.d/wblist.conf    
	# 添加iptables相关规则                                           
	iptables -t nat -A SHADOWSOCK -p tcp -m set --match-set customize_white dst -j RETURN
	[ "$ssgena" == '1' ] && iptables -t mangle -A SHADOWSOCK -p udp -m set --match-set customize_white dst -j RETURN
	#router itself
	[ "$ss_mode" != "homemode" ] && iptables -t nat -A OUTPUT -p tcp -m set --match-set router dst -j REDIRECT --to-ports 1081

}


start() {

	[ ! -s $CONF/ssserver.conf -a ! -s $CONF/ssserver_online.conf ] && logsh "【$service】" "没有添加ss服务器!" && exit 
	result=$(ps | grep -E 'ss-redir|ssr-redir' | grep -v grep | wc -l)
	if [ "$result" != '0'  ];then
		logsh "【$service】" "SS已经在运行！"	
		exit
	fi
	#添加定时更新规则
	cru a "$appname"_rule "20 5 * * * $monlorpath/apps/$appname/script/ss_rule_update.sh"
	cru a "$appname"_online "0 */6 * * * $monlorpath/apps/$appname/script/ss_online_update.sh"
	cru a "$appname" "0 6 * * * $monlorpath/apps/$appname/script/$appname.sh restart"

	get_config

	dnsconfig            

	load_nat
    	
	logsh "【$service】" "启动ss主进程($id)..."
	[ -z "$ss_mode" ] && logsh "【$service】" "未配置$appname运行模式！" && exit
	killall ss-redir &> /dev/null
	killall ssr-redir &> /dev/null
	service_start $APPPATH -b 0.0.0.0 -u -c $CONF/ss.conf 
	if [ $? -ne 0 ]; then
		logsh "【$service】" "启动失败！"
		exit
	fi
	case $ss_mode in
		"gfwlist") ss_gfwlist ;;
		"whitelist") ss_whitelist ;;
		"wholemode") ss_wholemode ;;
		"homemode") ss_homemode ;;
		*) logsh "【$service】" "ss运行模式错误！" ;;
	esac

	if [ "$ssgena" == 1 ]; then             
		logsh "【$service】" "启动ss游戏进程($ssgid)..."
		[ -z "$ssg_mode" ] && logsh "【$service】" "未配置$appname游戏运行模式！" && exit
		if [ "$ssgid" != "$id" ]; then
			service_start $BIN/ssg-redir -b 0.0.0.0 -u -c $CONF/ssg.conf
                	if [ $? -ne 0 ]; then
                       	 	logsh "【$service】" "启动失败！"
                        	exit
                	fi
                	ssg_port=1085
                else
                	ssg_port=1081
                fi	
		case $ssg_mode in
		"cngame") ss_cngame ;;
		"frgame") ss_frgame ;;
		*) logsh "【$service】" "ss游戏模式错误！" ;;
		esac
	fi
	
  	iptablenu=$(iptables -nvL PREROUTING -t nat | sed 1,2d | sed -n '/KOOLPROXY/=' | head -n1)
	if [ -z "$iptablenu" ];then
	# 	let iptablenu=$iptablenu-1
	# else
		iptablenu=2
	fi
	iptables -t nat -I PREROUTING "$iptablenu" -p tcp -j SHADOWSOCKS
	[ "$ssgena" == '1' ] && iptables -t mangle -A PREROUTING -p udp -j SHADOWSOCKS

	/etc/init.d/dnsmasq restart
	logsh "【$service】" "启动$appname服务完成！"

}

gfwlist_ipset() {
	sed -i 's/7913/15353/g' $CONF/gfwlist.conf
	ln -s $CONF/gfwlist.conf /etc/dnsmasq.d/gfwlist_ipset.conf
	ipset -N gfwlist iphash -!
}

chnroute_ipset() {
	sed -e "s/^/-A nogfwnet &/g" -e "1 i\-N nogfwnet hash:net" $CONF/chnroute.txt | ipset -R -!
}

ss_gfwlist() {

	logsh "【$service】" "添加国外黑名单规则..."
	gfwlist_ipset
	iptables -t nat -A SHADOWSOCK -p tcp -m set --match-set customize_black dst -j REDIRECT --to-port 1081
	iptables -t nat -A SHADOWSOCK -p tcp -m set --match-set gfwlist dst -j REDIRECT --to-port 1081

}

ss_whitelist() {

	logsh "【$service】" "添加国外白名单规则..."                                    
	chnroute_ipset
	iptables -t nat -A SHADOWSOCK -p tcp -m set --match-set customize_black dst -j REDIRECT --to-ports 1081
	iptables -t nat -A SHADOWSOCK -p tcp -m set ! --match-set nogfwnet dst -j REDIRECT --to-ports 1081 
}

ss_cngame() {

	logsh "【$service】" "添加国内游戏iptables规则..."
	[ "$ss_mode" != "gfwlist" ] && gfwlist_ipset
	iptables -t mangle -A SHADOWSOCK -p udp -m set ! --match-set gfwlist dst -j TPROXY --on-port "$ssg_port" --tproxy-mark 0x01/0x01         

}

ss_frgame() {

	logsh "【$service】" "添加国外游戏iptables规则..."
	[ "$ss_mode" != "whitelist" ] && chnroute_ipset
	iptables -t mangle -A SHADOWSOCK -p udp -m set ! --match-set nogfwnet dst -j TPROXY --on-port "$ssg_port" --tproxy-mark 0x01/0x01

}

ss_wholemode() {

	logsh "【$service】" "添加全局模式iptables规则..."
	iptables -t nat -A SHADOWSOCK -p tcp -j REDIRECT --to-ports 1081

}

ss_homemode() {

	logsh "【$service】" "添加回国模式规则..."
	[ "$ss_mode" != "whitelist" ] && chnroute_ipset
	iptables -t nat -A SHADOWSOCK -p tcp -m set --match-set customize_black dst -j REDIRECT --to-ports 1081
	iptables -t nat -A SHADOWSOCK -p tcp -m set --match-set nogfwnet dst -j REDIRECT --to-ports 1081 

}


stop() {
	
	logsh "【$service】" "关闭ss主进程..."
	killall -9 ss-redir > /dev/null 2>&1
	killall -9 ssr-redir > /dev/null 2>&1
	killall -9 ssg-redir > /dev/null 2>&1
	killall -9 ss-local > /dev/null 2>&1
	killall -9 ssr-local > /dev/null 2>&1
	killall -9 dns2socks > /dev/null 2>&1
	#删除定时规则
	cru d "$appname"
	cru d "$appname"_online
	cru d "$appname"_rule
	#ps | grep dns2socks | grep -v grep | xargs kill -9 > /dev/null 2>&1
	stop_ss_rules

}

stop_ss_rules() {

	logsh "【$service】" "清除iptables规则..."
	cd /tmp
	iptables -t nat -S | grep -E 'SHADOWSOCK|SHADOWSOCKS'| sed 's/-A/iptables -t nat -D/g'|sed 1,2d > clean.sh && chmod 777 clean.sh && ./clean.sh && rm clean.sh
	ip rule del fwmark 0x01/0x01 table 300 &> /dev/null
	ip route del local 0.0.0.0/0 dev lo table 300 &> /dev/null
	iptables -t mangle -D PREROUTING -p udp -j SHADOWSOCKS &> /dev/null
	iptables -t nat -D PREROUTING -p tcp -j SHADOWSOCKS &> /dev/null
	iptables -t mangle -F SHADOWSOCKS &> /dev/null
	iptables -t mangle -X SHADOWSOCKS &> /dev/null
	iptables -t mangle -F SHADOWSOCK &> /dev/null
	iptables -t mangle -X SHADOWSOCK &> /dev/null
	iptables -t nat -F SHADOWSOCK &> /dev/null
	iptables -t nat -X SHADOWSOCK &> /dev/null
	iptables -t nat -F SHADOWSOCKS &> /dev/null
	iptables -t nat -X SHADOWSOCKS &> /dev/null
	ipset destroy nogfwnet &> /dev/null
	ipset destroy gfwlist &> /dev/null
	ipset destroy customize_black &> /dev/null
	ipset destroy customize_white &> /dev/null
	ipset destroy router &> /dev/null
	# iptables -t nat -D PREROUTING -s $lanip/24 -p udp --dport 53 -j DNAT --to $dns_red_ip > /dev/null 2>&1
	eval `iptables -t nat -S | grep "$appname"-dns | head -1 | sed -e "s/-A/iptables -t nat -D/"` &> /dev/null
	iptables -t nat -D OUTPUT -p tcp -m set --match-set router dst -j REDIRECT --to-ports 1081 &> /dev/null
	chmod +x /opt/filetunnel/stunserver > /dev/null 2>&1
	rm -rf $CONF/ss.conf
	rm -rf $CONF/dns2socks.conf
	rm -rf $CONF/ssg.conf
	rm -rf $BIN/ssg-redir
	rm -rf /tmp/wblist.conf
	rm -rf /tmp/gfwlist_ipset.conf
	rm -rf /tmp/sscdn.conf
	rm -rf /etc/dnsmasq.d/gfwlist_ipset.conf > /dev/null 2>&1
	rm -rf /etc/dnsmasq.d/wblist.conf > /dev/null 2>&1
	rm -rf /etc/dnsmasq.d/cdn.conf &> /dev/null
	# /etc/init.d/dnsmasq restart
}


restart() 
{
	stop
	sleep 1
	start

}

status() {

	result1=$(pssh | grep $BIN | grep -v grep | wc -l)
	#http_status=`curl  -s -w %{http_code} https://www.google.com.hk/images/branding/googlelogo/1x/googlelogo_color_116x41dp.png -k -o /dev/null --socks5 127.0.0.1:1082`
	#if [ "$result" == '0' ] || [ "$http_status" != "200" ]; then
	result2=$(iptables -t nat -S | grep -c SHADOWSOCK)
	[ "$ssgena" == '1' ] && ssgflag=", 游戏节点: $ssgid($ssg_mode)"
	if [ "$result1" -ge "3" ]; then
		if [ "$result2" -ge 8 ]; then
			echo "运行节点: $id($ss_mode)$ssgflag" 
			echo "1"
		else
			echo "ss链路异常，可以尝试重启服务！"
			echo "0"
		fi
	else
		echo "未运行"
		echo "0"
	fi

}

backup() {

	mkdir -p $monlorbackup/$appname
	cp -rf $CONF/ssserver* $monlorbackup/$appname/
	cp -rf $CONF/sscontrol.conf $monlorbackup/$appname/sscontrol.conf
	cp -rf $CONF/customize_* $monlorbackup/$appname/

}

recover() {

	cp -rf $monlorbackup/$appname/ssserver* $CONF/
	cp -rf $monlorbackup/$appname/sscontrol.conf $CONF/sscontrol.conf
	cp -rf $monlorbackup/$appname/customize_* $CONF/

}