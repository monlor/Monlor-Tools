#!/bin/sh
#copyright by monlor

monlorurl_coding="https://coding.net/u/monlor/p/Monlor-Tools/git/raw/master"
monlorurl_github="https://raw.githubusercontent.com/monlor/Monlor-Tools/master"
monlorurl_test="https://coding.net/u/monlor/p/Monlor-Test/git/raw/master"
monlorurl=$(uci -q get monlor.tools.url) || monlorurl="$monlorurl_coding"
monlorpath=$(uci -q get monlor.tools.path)
userdisk=$(uci -q get monlor.tools.userdisk)
monlorbackup="/etc/monlorbackup"
[ -z "$userdisk" ] && userdisk="$monlorpath"
wanip=$(ubus call network.interface.wan status | grep \"address\" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
lanip=$(uci get network.lan.ipaddr)
profilepath=$(uci -q get monlor.tools.profilepath) || profilepath="$monlorpath/scripts"
libpath=$(uci -q get monlor.tools.libpath) || libpath="/usr/lib:/lib"
monlorver=$(uci -q get monlor.tools.version)

xq=$(cat /proc/xiaoqiang/model)
if [ "$xq" == "R1D" -o "$xq" == "R2D" -o "$xq" == "R3D"  ]; then
	model=arm
elif [ "$xq" == "R3" -o "$xq" == "R3P" -o "$xq" == "R3G" -o "$xq" == "R1CM" ]; then
	model=mips
fi

# 备份uci配置，主要为了系统升级后能恢复配置
if [ -f "/etc/config/monlor" ]; then
	[ ! -f $monlorpath/config/monlor.uci ] && touch $monlorpath/config/monlor.uci
	md5_1=$(md5sum /etc/config/monlor | cut -d' ' -f1)
	md5_2=$(md5sum $monlorpath/config/monlor.uci | cut -d' ' -f1)
	if [ "$md5_1" != "$md5_2" ]; then
		cp -rf /etc/config/monlor $monlorpath/config/monlor.uci
	fi
fi

checkuci() {
	# 最初用来检查插件的uci是否存在，现在当插件已经安装则返回0
	result=$(uci -q get monlor.$1)
	if [ ! -z "$result" -a -d $monlorpath/apps/$1 ]; then
		return 0
	else
		return 1
	fi

}

checkread() {
	# 传入参数为0或1则返回0，否则返回1
	if [ "$1" == '1' -o "$1" == '0' ]; then
		return 0
	else
		return 1
	fi
}

cutsh() {
	# 传入要分割的文本和要分割出的位置，以逗号分割
	if [ ! -z "$1" -a ! -z "$2" ]; then
		echo `echo $1 | cut -d',' -f$2`
		return 0
	elif [ ! -z "$1" -a -z "$2" ]; then
		echo `xargs | cut -d',' -f$1`
		return 0
	else
		return 1
	fi

}

logsh() {
	# 输出信息到/tmp/messages和标准输出，-s只输入到标准输出，-p只输入到日志文件
	if [ "$3" == "-s" ]; then
		logger -s -t "$1" "$2"
	elif [ "$3" == "-p" ]; then
		logger -p 1 -t "$1" "$2"
	else
		logger -s -p 1 -t "$1" "$2"
	fi
	return 0
	
}

compare() {
	# 版本号对比，传入在线版本和本地版本，若有更新返回0，否则返回1
	local ver1="$1"
	local ver2="$2"
	[ -z "$ver1" -o -z "$ver2" ] && return 1
	[ "$ver1" == "$ver2" ] && return 1
	result1=$(echo "$ver1" | grep -c "^[0-9][0-9]*\(\.[0-9][0-9]*\)\{2,3\}$")
	result2=$(echo "$ver2" | grep -c "^[0-9][0-9]*\(\.[0-9][0-9]*\)\{2,3\}$")
	[ "$result1" == '0' -o "$result2" == '0' ] && return 1 
	local newver="$ver2"
	local ver1_num=""
	local ver2_num=""
	for i in $(seq 1 4)
	do
		ver1_num=$(echo $ver1 | cut -d'.' -f"$i")
		ver2_num=$(echo $ver2 | cut -d'.' -f"$i")
		[ -z "$ver1_num" -a -z "$ver2_num" ] && break
		[ -z "$ver1_num" ] && newver="$ver2" && break
		[ -z "$ver2_num" ] && newver="$ver1" && break
		if [[ "$ver1_num" != "$ver2_num" ]]; then
			[ "$ver1_num" -gt "$ver2_num" ] && newver="$ver1"
			break
		fi
	done
	# newver=$(echo -e "$ver1\n$ver2" | sort -t. -n -k 1,1 -k 2,2 -k 3,3 -k 4,4 | tail -1)
	if [ "$newver" == "$ver2" ]; then
		return 1
	elif [ "$newver" == "$ver1" ]; then
		return 0
	fi

}

wgetsh() {
	# 传入下载的文件位置和下载地址，自动下载到/tmp，若成功则移到下载位置
	[ -z "$1" -o -z "$2" ] && return 1
	local wgetfilepath="$1"
	local wgetfilename=$(basename $wgetfilepath)
	local wgetfiledir=$(dirname $wgetfilepath)
	local wgeturl="$2"
	[ ! -d "$wgetfiledir" ] && mkdir -p $wgetfiledir
	[ ! -d /tmp/monlortmp ] && mkdir -p /tmp/monlortmp
	rm -rf /tmp/monlortmp/$wgetfilename
	result=$(curl -skL -w %{http_code} -o "/tmp/monlortmp/$wgetfilename" "$wgeturl")
	if [ $? -eq 0 -a "$result" == "200" ]; then
		chmod +x /tmp/monlortmp/$wgetfilename > /dev/null 2>&1
		mv -f /tmp/monlortmp/$wgetfilename $wgetfilepath > /dev/null 2>&1
		return 0
	else
		rm -rf /tmp/monlortmp/$wgetfilename
		return 1
	fi

}

ucish() {
        #monlor.$appname.$uciname_$key=$value 通过uci更轻松的存储数据
        #采用了key，value对形式储存数据，调用前设置appname和uciname值，uciname默认值为info
        local method="$1"
        local key="$2"
        local value="$3"
        [ -z "$method" ] && method="help"
        [ -z "$uciname" ] && uciname="$(nvram get uciname)" 
        [ -z "$appname" ] && appname="$(nvram get appname)"
        [ -z "$uciname" ] && uciname="info"
        case "$method" in
        get)
		uci -q get monlor."$appname"."$uciname"_"$key"
		;;
        set)
		uci -q set monlor."$appname"."$uciname"_"$key"="$value"
		;;
        del)
		uci -q del monlor."$appname"."$uciname"_"$key"
		;;
        keys)
		[ -n "$2" ] && uciname="$2"
		uci -q show monlor."$appname" | grep "$uciname"_ | awk -F '=' '{print$1}' | sed -e "s/monlor\."$appname"\."$uciname"_//g"
		;;
        values)
		[ -n "$2" ] && uciname="$2"
		uci -q show monlor."$appname" | grep "$uciname"_ | awk -F '=' '{print$2}'
		;;
        show)
		[ -n "$2" ] && uciname="$2"
		uci -q show monlor."$appname" | grep "$uciname"_ | sed -e "s/monlor\."$appname"\."$uciname"_//g" | awk -F '=' '{print$1"["$2"]"}' 
        	;;
        clear)
		uci -q show monlor."$appname" | grep "$uciname"_ | awk -F '=' '{print$1}' | sed -e "s/monlor\."$appname"\.//g" | while read line
		do
			uci -q del monlor."$appname"."$line"
		done
		;;
	export)
		[ -n "$2" ] && appname="$2" && nvram set appname="$2"
		uci -q show monlor."$appname" | sed 1d | sed -e "s/monlor\."$appname"\.//g" | grep -v ^"$uciname"_ | sed -e "s/=/=\"/" | sed -e "s/$/&\"/" | tr "\n" ";" 
		# grep -vE "\.[^=]*_|$appname=config"
		;;
        *)
		echo -e "Usage: ucish {get|set|del|export|show|clean} [key] [value]"
		echo -e "Options:"
		echo -e "\tget\tGet value by key"
		echo -e "\tset\tSet key and value"
		echo -e "\tdel\tDelete info by key"
		echo -e "\tkeys\tShow all key"
		echo -e "\tvalues\tShow all value"
		echo -e "\tshow\tShow all key and value"
		echo -e "\tclear\tClear all info"
		echo -e "\texport\tGet app configure"
		return 1
		;;
        esac
        [ $? -eq 0 ] && uci commit monlor
        return 0

}

cru() {
	# 添加定时任务，利用uci来储存信息，cru {a|d|c} [name] [crontab] 
	local method="$1"
	local name="$2"
	local content="$3"
	local appname=tools
	local uciname=cru
	[ -z "$method" ] && return 1

	case "$method" in
	a) 
		[ -z "$name" -o -z "$content" ] && return 1
		ucish set "$name" "$content"
		;;
	d) 
		[ -z "$name" ] && return 1
		ucish del "$name"
	 	;;
	c)
		ucish clear
		;;
	l)
		ucish show
		;;
	esac

	# 使定时任务生效
	sed -i "/#monlor-cru/d" /etc/crontabs/root
	if [ ! -z "`ucish keys`" ]; then
		ucish values | sed -e 's/.*/& #monlor-cru/g' >> /etc/crontabs/root	
	fi

	return 0

}

pssh() {

	local method="$1"
	if [ "$method" == 'c' ]; then
		rm -rf /tmp/pstmp.txt
	else
		[ ! -f /tmp/pstmp.txt -o ! -s /tmp/pstmp.txt ] && ps -w > /tmp/pstmp.txt
		cat /tmp/pstmp.txt
	fi

}

pingsh() {

	ping qq.com -c 2 &> /dev/null
	result1="$?"
	ping baidu.com -c 2 &> /dev/null
	result2="$?"
	[ "$result1" -eq 0 -o "$result2" -eq 0 ] && return 0 || return 1

}

echosh() {
	local length=""
	local string=""
	if [ -z "$2" ]; then
		length="$1"
		string="$(xargs)"
	else
		string="$1"
		length="$2"
	fi
	if [ "${#string}" -gt "$length" ]; then
		let length="$length"-2
		string="$(echo "$string" | cut -b 1-"$length")"..
	fi
	echo -e "$string"
}