#!/bin/ash
#copyright by monlor
monlorpath=$(uci -q get monlor.tools.path)
[ $? -eq 0 ] && source "$monlorpath"/scripts/base.sh || exit
eval `ucish export shadowsocks`
online_config=$monlorpath/apps/$appname/config/ssserver_online.conf
local_config=$monlorpath/apps/$appname/config/ssserver.conf

decode_url_link(){
	link=$1
	num=$2
	len=$((${#link}-$num))
	mod4=$(($len%4))
	if [ "$mod4" -gt "0" ]; then
		var="===="
		newlink=${link}${var:$mod4}
		echo -n "$newlink" | sed 's/-/+/g; s/_/\//g' | base64 -d 2>/dev/null
	else
		echo -n "$link" | sed 's/-/+/g; s/_/\//g' | base64 -d 2>/dev/null
	fi
}

get_ss_config() {
	decode_link="$1"
	server=$(echo "$decode_link" |awk -F':' '{print $1}')
	server_port=$(echo "$decode_link" |awk -F':' '{print $2}')
	protocol=$(echo "$decode_link" |awk -F':' '{print $3}')
	encrypt_method=$(echo "$decode_link" |awk -F':' '{print $4}')
	obfs=$(echo "$decode_link" |awk -F':' '{print $5}'|sed 's/_compatible//g')
	#password=$(echo "$decode_link" |awk -F':' '{print $6}'|awk -F'/' '{print $1}')
	
	password=$(decode_url_link $(echo "$decode_link" |awk -F':' '{print $6}'|awk -F'/' '{print $1}') 0)
	
	obfsparam_temp=$(echo "$decode_link" |awk -F':' '{print $6}'|grep -Eo "obfsparam.+"|sed 's/obfsparam=//g'|awk -F'&' '{print $1}')
	[ -n "$obfsparam_temp" ] && obfsparam=$(decode_url_link $obfsparam_temp 0) || obfsparam=''
	
	protoparam_temp=$(echo "$decode_link" |awk -F':' '{print $6}'|grep -Eo "protoparam.+"|sed 's/protoparam=//g'|awk -F'&' '{print $1}')
	[ -n "$protoparam_temp" ] && protoparam=$(decode_url_link $protoparam_temp 0|sed 's/_compatible//g') || protoparam=''
	
	remarks_temp=$(echo "$decode_link" |awk -F':' '{print $6}'|grep -Eo "remarks.+"|sed 's/remarks=//g'|awk -F'&' '{print $1}')
	[ -n "$remarks_temp" ] && remarks=$(decode_url_link $remarks_temp 0 | tr "\n" " " | sed -e "s/ //g") || remarks="$server"
	
	group_temp=$(echo "$decode_link" |awk -F':' '{print $6}'|grep -Eo "group.+"|sed 's/group=//g'|awk -F'&' '{print $1}')
	[ -n "$group_temp" ] && group=$(decode_url_link $group_temp 0) || group='AutoSuBGroup'
	# [ -n "$group" ] && group_base64=`echo $group | base64_encode | sed 's/ -//g'`
	# [ -n "$server" ] && server_base64=`echo $server | base64_encode | sed 's/ -//g'`	
	#把全部服务器节点写入文件 /usr/share/shadowsocks/serverconfig/all_onlineservers

}

local_update() {

	if [ -n "$ssuri" ]; then
		# 检测ss ssr
		NODE_FORMAT1=`echo $ssuri | grep -E "^ss://"`
		NODE_FORMAT2=`echo $ssuri | grep -E "^ssr://"`
		if [ -n "$NODE_FORMAT1" ];then
			logsh "【$service】" "暂不支持ss节点订阅..." && exit
		elif [ -n "$NODE_FORMAT2" ];then
			urllinks=$(echo $ssuri | sed 's/ssr:\/\///g')
			decode_link=$(decode_url_link $urllinks 0)
			get_ss_config $decode_link
			read -p "确定要添加节点：[$remarks,$server,$server_port,$password,$encrypt_method...][1/0]? " res
			if [ "$res" == '1' ]; then
				cat "$local_config" | grep -v "$remarks" > /tmp/server.conf
				mv -f /tmp/server.conf "$local_config"
				echo "$remarks,$server,$server_port,$password,$encrypt_method,$protocol,$obfs,$protoparam,$obfsparam" >> "$local_config"
			fi
		fi
	fi

}

online_update() {

	if [ -n "$ssr_subscribe_link" ]; then
		
		logsh "【$service】" "更新$appname订阅节点"
		wgetsh /tmp/ssr_subscribe_file.txt $ssr_subscribe_link
		[ $? -ne 0 ] && logsh "【$service】" "下载订阅节点失败！" && exit
		decode_url_link `cat /tmp/ssr_subscribe_file.txt` 0 > /tmp/ssr_subscribe_file_temp1.txt
		# 检测ss ssr
		NODE_FORMAT1=`cat /tmp/ssr_subscribe_file_temp1.txt | grep -E "^ss://"`
		NODE_FORMAT2=`cat /tmp/ssr_subscribe_file_temp1.txt | grep -E "^ssr://"`
		if [ -n "$NODE_FORMAT1" ];then
			logsh "【$service】" "暂不支持ss节点订阅..." && exit
		elif [ -n "$NODE_FORMAT2" ];then
			maxnum=$(decode_url_link `cat /tmp/ssr_subscribe_file.txt` 0 | grep "MAX=" | awk -F"=" '{print $2}' | grep -Eo "[0-9]+")
			if [ -n "$maxnum" ]; then
				urllinks=$(decode_url_link `cat /tmp/ssr_subscribe_file.txt` 0 | sed '/MAX=/d' | shuf -n $maxnum | sed 's/ssr:\/\// /g')
			else
				urllinks=$(decode_url_link `cat /tmp/ssr_subscribe_file.txt` 0 | sed 's/ssr:\/\// /g')
			fi
			[ -z "$urllinks" ] && logsh "【$service】" "订阅节点解析失败！" && exit
			echo -n > $online_config
			for link in $urllinks
			do
				decode_link=$(decode_url_link $link 0)
				get_ss_config $decode_link
				logsh "【$service】" "添加$appname订阅节点：$remarks[$server]" -s
				echo "$remarks,$server,$server_port,$password,$encrypt_method,$protocol,$obfs,$protoparam,$obfsparam" >> $online_config
			done
			logsh "【$service】" "ss订阅节点更新完成！"
			
		fi

	fi
}

if [ "$1" == "add" ]; then
	action="uri" 
	ssuri="$2"
	local_update
else
	online_update
fi







