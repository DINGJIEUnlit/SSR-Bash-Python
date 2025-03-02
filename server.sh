#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

#Check Root
[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }

#CheckOS
if [ -n "$(grep 'Aliyun Linux release' /etc/issue)" -o -e /etc/redhat-release ];then
OS=CentOS
[ -n "$(grep ' 7\.' /etc/redhat-release)" ] && CentOS_RHEL_version=7
[ -n "$(grep ' 6\.' /etc/redhat-release)" -o -n "$(grep 'Aliyun Linux release6 15' /etc/issue)" ] && CentOS_RHEL_version=6
[ -n "$(grep ' 5\.' /etc/redhat-release)" -o -n "$(grep 'Aliyun Linux release5' /etc/issue)" ] && CentOS_RHEL_version=5
elif [ -n "$(grep 'Amazon Linux AMI release' /etc/issue)" -o -e /etc/system-release ];then
OS=CentOS
CentOS_RHEL_version=6
elif [ -n "$(grep bian /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Debian' ];then
OS=Debian
[ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
Debian_version=$(lsb_release -sr | awk -F. '{print $1}')
elif [ -n "$(grep Deepin /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Deepin' ];then
OS=Debian
[ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
Debian_version=$(lsb_release -sr | awk -F. '{print $1}')
elif [ -n "$(grep Ubuntu /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Ubuntu' -o -n "$(grep 'Linux Mint' /etc/issue)" ];then
OS=Ubuntu
[ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
Ubuntu_version=$(lsb_release -sr | awk -F. '{print $1}')
[ -n "$(grep 'Linux Mint 18' /etc/issue)" ] && Ubuntu_version=16
else
echo "Does not support this OS, Please contact the author! "
kill -9 $$
fi
servercheck(){
	echo "1.启动服务"
	echo "2.停止服务"
	echo "3.重启服务"
	echo "4.查看日志"
	echo "5.重新配置"
	echo "6.测试数据"
	while :; do echo
		read -p "请选择： " serverch
		[ -z "$serverch" ] && break
		if [[ ! $serverch =~ ^[1-6]$ ]]; then
			echo "输入错误! 请输入正确的数字!"
		else
			break
		fi
	done

	if [[ $serverch == 1 ]];then
		PID=$(ps -ef |grep -v grep | grep "bash" | grep "servercheck.sh" | grep "run" | awk '{print $2}')
		if [[ ! -z ${PID} ]];then
			echo "服务已启动，无需操作"
			servercheck
		else
			nohup bash /usr/local/SSR-Bash-Python/servercheck.sh run 2>/dev/null &
			echo "服务已启动"
			servercheck
		fi
	fi
	if [[ $serverch == 2 ]];then
		PID=$(ps -ef |grep -v grep | grep "bash" | grep "servercheck.sh" | grep "run" | awk '{print $2}')
		if [[ -z ${PID} ]];then
			echo "进程不存在,无法停止"
			servercheck
		else
			bash /usr/local/SSR-Bash-Python/servercheck.sh stop
			servercheck
		fi
	fi
	if [[ $serverch == 3 ]];then
		PID=$(ps -ef |grep -v grep | grep "bash" | grep "servercheck.sh" | grep "run" | awk '{print $2}')
		if [[ -z ${PID} ]];then
			echo "进程不存在,无法重启服务"
			servercheck
		else
			bash /usr/local/SSR-Bash-Python/servercheck.sh stop
			nohup bash /usr/local/SSR-Bash-Python/servercheck.sh run 2>/dev/null &
			echo "重启成功"
			servercheck
		fi
	fi
	if [[ $serverch == 4 ]];then
		if [[ -e ${pwd}/check.log ]];then
			cat ${pwd}/check.log
			servercheck
		else
			echo "没有找到log文件！"
			servercheck
		fi
	fi
	if [[ $serverch == 5 ]];then
		echo "你将丢弃所有的日志记录数据，并进行重新配置[Y/N]"
		read yn
		if [[ $yn == [yY] ]];then
			PID=$(ps -ef |grep -v grep | grep "bash" | grep "servercheck.sh" | grep "run" | awk '{print $2}')
			if [[ ! -z ${PID} ]];then
				kill -9 ${PID}
			fi
			bash /usr/local/SSR-Bash-Python/servercheck.sh reconf
			echo "完毕请启动服务"
			echo ""
			servercheck
		fi
	fi
	if [[ $serverch == 6 ]];then
		if [[ -e ${pwd}/state.log ]];then
			cat ${pwd}/state.log
			servercheck
		else
			echo "没有找到测试数据！"
			servercheck
		fi
	fi
}
echo ""
echo "1.启动服务"
echo "2.停止服务"
echo "3.重启服务"
echo "4.查看日志"
echo "5.运行状态"
echo "6.修改DNS"
echo "7.开启用户WEB面板"
echo "8.关闭用户WEB面板"
echo "9.启用服务端开机启动"
echo "10.服务器自动巡检系统"
echo "11.服务器网络与IO测速"
echo "直接回车返回上级菜单"

while :; do echo
	read -p "请选择： " serverc
	[ -z "$serverc" ] && ssr && break
	if [[ ! $serverc =~ ^[1-9]$ ]]; then
		if [[ $serverc == 10 ]]||[[ $serverc == 11 ]]; then
			break
		fi
		echo "输入错误! 请输入正确的数字!"
	else
		break	
	fi
done

if [[ $serverc == 1 ]];then
	bash /usr/local/shadowsocksr/logrun.sh
	iptables-restore < /etc/iptables.up.rules
	clear
	echo "ShadowsocksR服务器已启动"
	echo ""
	bash /usr/local/SSR-Bash-Python/server.sh
fi

if [[ $serverc == 2 ]];then
	bash /usr/local/shadowsocksr/stop.sh
	echo "ShadowsocksR服务器已停止"
	echo ""
	bash /usr/local/SSR-Bash-Python/server.sh
fi

if [[ $serverc == 3 ]];then
	bash /usr/local/shadowsocksr/stop.sh
	bash /usr/local/shadowsocksr/logrun.sh
	iptables-restore < /etc/iptables.up.rules
	clear
	echo "ShadowsocksR服务器已重启"
	echo ""
	bash /usr/local/SSR-Bash-Python/server.sh
fi

if [[ $serverc == 4 ]];then
	trap 'bash /usr/local/SSR-Bash-Python/server.sh' 2
	bash /usr/local/shadowsocksr/tail.sh
fi

if [[ $serverc == 5 ]];then
	ps aux|grep server.py
	bash /usr/local/SSR-Bash-Python/server.sh
fi

if [[ $serverc == 6 ]];then
	read -p "输入主要 DNS 服务器: " ifdns1
	read -p "输入次要 DNS 服务器: " ifdns2
	echo "nameserver $ifdns1" > /etc/resolv.conf
	echo "nameserver $ifdns2" >> /etc/resolv.conf
	echo "DNS 服务器已设置为  $ifdns1 $ifdns2"
	echo ""
	bash /usr/local/SSR-Bash-Python/server.sh
fi

if [[ $serverc == 7 ]];then
	P_V=`python -V 2>&1 | awk '{print $2}'`
	P_V1=`python -V 2>&1 | awk '{print $2}' | awk -F '.' '{print $1}'`
	if [[ ${P_V1} == 3 ]];then
		echo "你当前的python版本不支持此功能"
		echo "当前版本：${P_V} ,请降级至2.x版本"
		echo ""
		bash /usr/local/SSR-Bash-Python/server.sh
		exit 1
	fi
	while :; do echo
		read -p "请输入自定义的WEB端口：" cgiport
		if [[ "$cgiport" =~ ^(-?|\+?)[0-9]+(\.?[0-9]+)?$ ]];then
			break
		else
			echo 'Input Error!'
		fi
	done
	#Set Firewalls
	if [[ ${OS} =~ ^Ubuntu$|^Debian$ ]];then
		iptables-restore < /etc/iptables.up.rules
		clear
		iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport $cgiport -j ACCEPT
		iptables -I INPUT -m state --state NEW -m udp -p udp --dport $cgiport -j ACCEPT
		iptables-save > /etc/iptables.up.rules
	fi

	if [[ ${OS} == CentOS ]];then
		if [[ $CentOS_RHEL_version == 7 ]];then
			iptables-restore < /etc/iptables.up.rules
			iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport $cgiport -j ACCEPT
    		iptables -I INPUT -m state --state NEW -m udp -p udp --dport $cgiport -j ACCEPT
			iptables-save > /etc/iptables.up.rules
		else
			iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport $cgiport -j ACCEPT
    		iptables -I INPUT -m state --state NEW -m udp -p udp --dport $cgiport -j ACCEPT
			/etc/init.d/iptables save
			/etc/init.d/iptables restart
		fi
	fi
	#Get IP
	ip=`curl -m 10 -s http://members.3322.org/dyndns/getip`
	clear
	chmod -R 777 /usr/local/SSR-Bash-Python
	cd /usr/local/SSR-Bash-Python/www
	screen -dmS webcgi python -m CGIHTTPServer $cgiport
	echo "WEB服务启动成功，请访问 http://${ip}:$cgiport"
	echo ""
	bash /usr/local/SSR-Bash-Python/server.sh
fi

if [[ $serverc == 8 ]];then
	cgipid=$(ps -ef|grep 'webcgi' |grep -v grep |awk '{print $2}')
	kill -9 $cgipid
	screen -wipe
	clear
	echo "WEB服务已关闭！"
	echo ""
	bash /usr/local/SSR-Bash-Python/server.sh
fi

if [[ $serverc == 9 ]];then
	if [[ ${OS} == Ubuntu || ${OS} == Debian ]];then
    	cat >/etc/init.d/ssr-bash-python <<EOF
#!/bin/sh
### BEGIN INIT INFO
# Provides:          SSR-Bash_python
# Required-Start: $local_fs $remote_fs
# Required-Stop: $local_fs $remote_fs
# Should-Start: $network
# Should-Stop: $network
# Default-Start:        2 3 4 5
# Default-Stop:         0 1 6
# Short-Description: SSR-Bash-Python
# Description: SSR-Bash-Python
### END INIT INFO
iptables-restore < /etc/iptables.up.rules
bash /usr/local/shadowsocksr/logrun.sh
EOF
    	chmod 755 /etc/init.d/ssr-bash-python
    	chmod +x /etc/init.d/ssr-bash-python
    	cd /etc/init.d
    	update-rc.d ssr-bash-python defaults 95
	fi

	if [[ ${OS} == CentOS ]];then
    	echo "
iptables-restore < /etc/iptables.up.rules
bash /usr/local/shadowsocksr/logrun.sh
bash /usr/local/SSR-Bash-Python/servercheck.sh hide
" > /etc/rc.d/init.d/ssr-bash-python
    	chmod +x  /etc/rc.d/init.d/ssr-bash-python
    	echo "/etc/rc.d/init.d/ssr-bash-python" >> /etc/rc.d/rc.local
    	chmod +x /etc/rc.d/rc.local
	fi
	echo "开机启动设置完成！"
        echo ""
	bash /usr/local/SSR-Bash-Python/server.sh
fi

if [[ $serverc == 10 ]];then
	servercheck
	bash /usr/local/SSR-Bash-Python/server.sh
fi	

if [[ $serverc == 11 ]];then
    bash /usr/local/SSR-Bash-Python/ZBench-CN.sh
	bash /usr/local/SSR-Bash-Python/server.sh
fi