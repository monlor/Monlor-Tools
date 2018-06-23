#!/bin/ash
#copyright by monlor
source "$(uci -q get monlor.tools.path)"/scripts/base.sh 

logsh "【Tools】" "正在更新工具箱程序... "
command -v wgetsh > /dev/null 2>&1
wgetenable="$?"
if [ "$1" != "-f" ]; then
	#检查更新
	if [ "$wgetenable" -ne 0 ]; then
		logsh "【Tools】" "使用临时的下载方式"
		result=$(curl -skL -w %{http_code} -o /tmp/tools.txt $monlorurl/config/version.txt)
	 	[ "$result" != "200" ] && logsh "【Tools】" "检查更新失败！" && exit
	else
		wgetsh /tmp/version/tools.txt $monlorurl/config/version.txt > /dev/null 2>&1
		[ $? -ne 0 ] && logsh "【Tools】" "检查更新失败！" && exit
	fi
	newver=$(cat /tmp/version/tools.txt)
	logsh "【Tools】" "当前版本$oldver，最新版本$monlorver"
	command -v compare > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		!(compare $newver $oldver) && logsh "【Tools】" "工具箱已经是最新版！" && exit
	else
		[ "$newver" == "$oldver" ] && logsh "【Tools】" "工具箱已经是最新版！" && exit
	fi
	logsh "【Tools】" "版本不一致，正在更新工具箱..."
fi
rm -rf /tmp/monlor.tar.gz
rm -rf /tmp/monlor
if [ "$wgetenable" -ne 0 ]; then
	logsh "【Tools】" "使用临时的下载方式"
	result=$(curl -skL -w %{http_code} -o "/tmp/monlor.tar.gz" "$monlorurl/appstore/monlor.tar.gz")
	[ "$result" != "200" ] && logsh "【Tools】" "工具箱文件下载失败！"  && exit
else 
	wgetsh "/tmp/monlor.tar.gz" "$monlorurl/appstore/monlor.tar.gz" > /dev/null 2>&1
	[ $? -ne 0 ] && logsh "【Tools】" "工具箱文件下载失败！"  && exit
fi
logsh "【Tools】" "解压工具箱文件"
tar -zxvf /tmp/monlor.tar.gz -C /tmp > /dev/null 2>&1
[ $? -ne 0 ] && logsh "【Tools】" "文件解压失败！" && exit
logsh "【Tools】" "更新工具箱配置脚本"
# 清除更新时不需要的文件
rm -rf /tmp/monlor/apps
rm -rf /tmp/monlor/scripts/dayjob.sh
rm -rf /tmp/monlor/config/monlor.uci
rm -rf /tmp/monlor/scripts/userscript.sh
# if [ "$model" == "mips" ]; then 
# 	if [ -f /tmp/monlor/config/applist_"$xq".txt ]; then
# 		mv -f /tmp/monlor/config/applist_"$xq".txt /tmp/monlor/config/applist.txt
# 	else
# 		mv -f /tmp/monlor/config/applist_mips.txt /tmp/monlor/config/applist.txt
# 	fi
# fi
# rm -rf /tmp/monlor/config/applist_*.txt
# 更新版本号(因为强制更新跳过版本号检查不会更新版本号)
[ "$1" == "-f" ] && cp -rf /tmp/monlor/config/version.txt /tmp/version/tools.txt
uci set monlor.tools.version="$(cat /tmp/monlor/config/version.txt)"
uci commit monlor
logsh "【Tools】" "更新工具箱文件"
cp -rf /tmp/monlor/config $monlorpath/
cp -rf /tmp/monlor/scripts $monlorpath/
cp -rf /tmp/monlor/web $monlorpath/
logsh "【Tools】" "赋予可执行权限"
chmod -R +x $monlorpath/scripts/*
chmod -R +x $monlorpath/config/*

# 更新web页面
[ "$(uci -q get monlor.tools.webui)" != '0' ] && $monlorpath/scripts/addweb

#旧版本处理
result=$(cat /etc/crontabs/root	| grep -c "#monlor-cru")
if [ "$result" == '0' ]; then
	sed -i "/monlor/d" /etc/crontabs/root	
	$monlorpath/scripts/init.sh
fi
[ -f $monlorpath/scripts/crontab.sh ] && rm -rf $monlorpath/scripts/crontab.sh
[ -f $monlorpath/scripts/wget.sh ] && rm -rf $monlorpath/scripts/wget.sh
[ -f $monlorpath/scripts/cru ] && rm -rf $monlorpath/scripts/cru
[ -f $monlorpath/scripts/dayjob.sh ] && rm -rf $monlorpath/scripts/dayjob.sh
[ -f $monlorpath/config/cru.conf ] && rm -rf $monlorpath/config/cru.conf

cat $monlorpath/config/applist.txt | while read line
do
	checkuci $line || continue
	[ -f $monlorpath/apps/$line/config/monlor.conf ] && break
	wgetsh $monlorpath/apps/$line/config/monlor.conf $monlorurl/apps/$line/config/monlor.conf
done
sed -i "/#monlor-tools/d" /etc/profile
sed -i "/LD_LIBRARY_PATH/d" /etc/profile
sed -i "s#:$monlorpath/scripts##" /etc/profile
cru d getver
cru d dayjob
[ ! -z "`mount | grep banner`" ] && umount -lf /etc/banner
[ "$(uci -q get monlor.tools.ins_method)" == '0' ] && uci set monlor.tools.ins_method=3 && uci commit monlor
#新增加功能设置
result=$(cat /etc/profile | grep -c monlor/config)
if [ "$result" == 0 ]; then
	echo "source $monlorpath/config/profile" >> /etc/profile
fi
cru a monitor "*/6 * * * * $monlorpath/scripts/monitor.sh"

logsh "【Tools】" "工具箱更新完成！更新内容如下："
echo "-----------------------------------------"
cat /tmp/monlor/newinfo.txt
echo
echo "-----------------------------------------"
echo 
# 旧版本没有已经安装的插件列表
compare "$(cat /tmp/monlor/config/version.txt)" 2.6.11
if [ $? -eq 1 ]; then
	rm -rf $monlorpath/config/applist.txt
	curl -skL $monlorurl/temp/applist.txt | while read line
	do
		checkuci $line && echo $line >> $monlorpath/config/applist.txt
	done
	rm -rf /tmp/applist.txt
	wgetsh /tmp/applist.txt $monlorurl/temp/applist_"$xq".txt
	if [ $? -ne 0 ]; then
		[ "$model" == "arm" ] && applist="applist.txt"
		[ "$model" == "mips" ] && applist="applist_mips.txt"
		wgetsh /tmp/applist.txt $monlorurl/temp/"$applist"
		[ $? -ne 0 ] && logsh "【Tools】" "获取失败，检查网络问题！"
	fi
fi

#删除临时文件
rm -rf /tmp/monlor.tar.gz
rm -rf /tmp/monlor