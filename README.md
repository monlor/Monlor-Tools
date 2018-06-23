# Monlor-Tools

![工具箱界面](https://raw.githubusercontent.com/monlor/Monlor-Tools/master/temp/img.png)

>工具箱正处于测试状态，更新比较频繁，安装要有一定的动手能力，出问题会用U盘刷固件。  
>arm路由: R1D R2D R3D，mips路由: R3 R3P R3G R1CM，才疏学浅，但有一颗学习和折腾的心！   
>目前支持了以下几种插件:  

>1. [ShadowSocks](https://github.com/shadowsocks/shadowsocks/tree/master)
>2. [KoolProxy](http://koolshare.b0.upaiyun.com/)
>3. [Aria2](http://aria2.github.io/)
>4. [VsFtpd](https://security.appspot.com/vsftpd.html)
>5. [kms](https://github.com/Wind4/vlmcsd)
>6. [Frpc](https://github.com/fatedier/frp)
>7. [Ngrok](https://github.com/dosgo/ngrok-c)
>8. [WebShell](https://github.com/shellinabox/shellinabox)
>9. [TinyProxy](https://github.com/tinyproxy/tinyproxy)
>10. [Entware](https://github.com/Entware/Entware-ng)
>11. [KodExplorer](https://kodcloud.com/)
>12. [EasyExplorer](http://koolshare.cn/thread-129199-1-1.html)
>13. [HttpFile](http://nginx.org/)
>14. [VerySync](http://verysync.com/)
>15. [FastDick](https://github.com/fffonion/Xunlei-Fastdick)
>16. [FireWall](https://www.netfilter.org/)

## 安装方式：  
#### 	插件的安装
	1. 离线安装插件，appmanage.sh add /tmp/kms.tar.gz安装插件 
	2. 在线安装插件，默认下载源coding.net，安装命令appmanage.sh add kms
	3. monlor命令一键安装插件[推荐]

#### 	一键安装命令
	sh -c "$(curl -kfsSl https://coding.net/u/monlor/p/Monlor-Tools/git/raw/master/install.sh)" && source /etc/profile &> /dev/null

## 工具箱命令：
	1. 卸载：uninstall.sh （不推荐）
	2. 更新：update.sh [-f] (不推荐)
	3. 初始化：init.sh 
	4. 插件管理：appmanage.sh add|upgrade|del appname [-f]
	5. 工具箱配置：monlor (任意界面Ctrl + c可以退出配置)
	6. 在线更新：sh -c "$(curl -kfsSl $(uci get monlor.tools.url)/scripts/update.sh)"
	7. 在线卸载：sh -c "$(curl -kfsSl $(uci get monlor.tools.url)/scripts/uninstall.sh)"

## 目录结构：  
	/
	|--- /etc  
	|--- /monlor
	|    |--- /apps/        --- 插件安装位置  
	|    |--- /config/      --- 工具箱配置文件
	|    |--- /scripts/     --- 工具箱脚本
	|    |--- /web/         --- web页面文件
	|--- /tmp
	|    |--- /messages     --- 系统日志，工具箱日志
	|--- /userdisk
	|    |--- /data/        --- 硬盘目录
	|--- /extdisks/
	|    |--- /sd*/         --- 外接盘目录
	|--- /var/
	|	 |--- /log/         --- 插件日志存放目录

## 注意事项
	1. 如果插件和工具箱都有更新，请务必先更新工具箱！
	2. 工具箱没有web界面，完全靠Shell开发，插件的安装、卸载、配置由配置文件完成。   
	3. 安装完成后执行monlor命令配置工具箱，Ctrl + c或者输入exit可以退出。 
	4. ss插件推荐使用aes-256-cfb或rc4-md5加密方式，mips平台较新的加密方式可能不支持。
	5. 关于迅雷快鸟FastDick，请按https://github.com/fffonion/Xunlei-Fastdick这里的教程运行swjsq.py并找到运行成功后生成的swjsq_wget.sh文件，提取里面的uid,pwd,peerid即可。
	6. 插件列表显示异常运行：rm -rf $(uci get monlor.tools.path)/config/applist.txt

## 更新内容：
	2018-06-16
		1. 工具箱新增web界面，暂时只有ss和kp两个插件，支持最新版固件
		2. 新增插件“自动签到”，arm平台aria2程序更新到1.34
		3. 工具箱旧的备份文件已不支持，请重新备份
		4. 优化了ss插件的iptables规则
		5. 新增插件filebrowser，web文件管理工具
		6. 本次更新可能导致旧版不能用，请及时更新，如果更新有问题，使用以下命令更新
		7. curl -skL $(uci get monlor.tools.url)/scripts/update.sh | sh

	2018-06-10
		1. aria2程序更新到1.34，ss程序更新到3.1.3
		2. ss插件增加ssr订阅添加节点方式

	2018-05-08
		1. 将多个插件程序使用upx压缩，减少路由器磁盘占用

	2018-04-29
		1. 修复ss插件规则更新失败的问题
		2. 工具箱添加环境变量文件
		3. ss插件增加回国模式，现在可自定义黑白名单规则
		4. ss插件ssr节点添加混淆参数设置
		5. 修改完samba配置后增加重启samba程序的步骤以保证配置生效

	2018-04-01
		1. 优化了工具箱界面，愚人节快乐！

	2018-03-31
		1. 现已支持安装工具箱到内存空间，可不插入U盘安装工具箱，主要针对于小米路由器mini。
		2. 内存安装模式如果出现开机配置未恢复的情况，可手动运行:monlor recover

	2018-03-30
		1. 工具箱默认不再开通22端口，请安装FireWall插件开通
		2. ss插件已支持小米路由器R1CM，注意先更新工具箱

	2018-03-29
		1. 修复更新脚本无法更新的问题(感谢@michealhansun测试)
		2. 修复了R3上aria2插件无法运行的问题(感谢@michealhansun测试)

	2018-03-24
		1. 修复ss插件运行ssr节点的显示问题，感谢@Ken反馈
		2. 修复ss插件菜单状态显示问题

	2018-03-11
		1. 修复appmanage.sh插件安装脚本的BUG

	2018-03-10
		1. 修复了R3G上ss插件无法运行的问题，感谢@有个桃
		2. 更新了封装的一些功能，导致有所插件必须更新
		3. ss插件目前测试兼容了R1/2/3D、R3这些型号，R3G等型号待测试
		4. 修复了mips上aria2插件的问题，R3测试正常(感谢@wanghurui)，R3G上未测试
		5. 修复aria2脚本及配置的多出BUG

	2018-02-27
		1. 更新arm的frpc版本为0.16.0
		2. 修复KoolProxy运行命令的一个小问题
		3. 顺带解决一下小米路由器R2D（或其他型号上）可能出现的top命令使用的问题
		4. 更新封装功能ucish和cru到工具箱，将影响到插件FireWall、Frpc和KoolProxy，更新工具箱请同时更新插件

	2018-02-14
		1. 优化了工具箱各个脚本，修复了版本号对比问题
		2. 增加插件迅雷快鸟FastDick，请根据https://github.com/fffonion/Xunlei-Fastdick这里的教程运行swjsq.py并找到运行成功后生成的swjsq_wget.sh文件，提取里面的uid,pwd,peerid即可。
		3. 优化了ss插件运行脚本和配置脚本
		4. 更新监控脚本，解决小米路由CPU占用100%的问题

	2018-02-08
		1. 修复了mips的KoolProxy无法使用https的问题，感谢@wanghurui的测试。

	2018-02-05 
		1. 修复了mips的verysync无法运行问题
		2. 更新了ss和kp规则更新方式
		3. 因为之前没有用在线获取更新脚本的方式更新，以前的版本请更新2次工具箱，update.sh && update.sh -f，以后的版本直接运行monlor更新即可。

	2018-02-04
		1. 修复了mips设备ss插件无法使用的问题，感谢@wanghurui的测试。
		2. 更新了VsFtpd插件，修复匿名模式问题

	2018-01-24
		1. 推送了版本号？

	2018-01-18
		1. 增加文件同步工具verysync，mips路由可能内存不足。

	2018-01-12
		1. 更新arm的Frpc版本至0.14.1
		2. 修复插件列表更新bug，更新失败的问题

	2018-01-10
		1. 增加插件HttpFile基于http的文件查看工具
		2. 增加了ss游戏模式acl局域网设备控制

	2018-01-09
		1. 修复工具箱安装脚本BUG

	2018-01-08
		1. 区分mips路由和arm路由的插件列表显示
		2. 完善备份功能，一键备份恢复

	2018-01-06
		1. 完成了所有功能的终端提示界面
		2. monlor命令可以管理插件，配置插件，更新卸载工具箱，备份恢复插件配置
		3. R3测试了部分插件
		4. 建议重新安装工具箱，安装完成配置好插件后，建议备份配置
		5. 只要路由器不坏，工具箱会坚持更新到有web界面的版本，重在学习

	

	

	

	


	



