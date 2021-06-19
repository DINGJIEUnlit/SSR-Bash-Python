#!/bin/bash 
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

#Check Root
[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }

#Check OS
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

#Define
test_URL="www.google.com"
Timeout="10"
ssr_dir="/usr/local/shadowsocksr"
ssr_local="${ssr_dir}/shadowsocks"
log_file="${pwd}/check.log"
state_file="${pwd}/state.log"
uname="test"
uport="1314"
upass=`date +%s | sha256sum | base64 | head -c 32`
um1="chacha20"
ux1="auth_chain_a"
uo1="tls1.2_ticket_auth"
local_port="1080"
uparam="1"
maxsize="$((1024*1024))"

#Function
mades(){
	echo "本程序需要创建帐号进行连通性测试[Y/N]"
	read -n 1 yn
	if [[ $yn == [Yy] ]];then
		if [[ ${OS} =~ ^Ubuntu$|^Debian$ ]];then
			iptables-restore < /etc/iptables.up.rules
			clear
			iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport $uport -j ACCEPT
			iptables -I INPUT -m state --state NEW -m udp -p udp --dport $uport -j ACCEPT
			iptables-save > /etc/iptables.up.rules
		fi

		if [[ ${OS} == CentOS ]];then
			if [[ $CentOS_RHEL_version == 7 ]];then
				iptables-restore < /etc/iptables.up.rules
				iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport $uport -j ACCEPT
    			iptables -I INPUT -m state --state NEW -m udp -p udp --dport $uport -j ACCEPT
				iptables-save > /etc/iptables.up.rules
			else
				iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport $uport -j ACCEPT
    			iptables -I INPUT -m state --state NEW -m udp -p udp --dport $uport -j ACCEPT
				/etc/init.d/iptables save
				/etc/init.d/iptables restart
			fi
		fi
		echo "用户添加成功！用户信息如下："
		cd /usr/local/shadowsocksr
		python mujson_mgr.py -a -u $uname -p $uport -k $upass -m $um1 -O $ux1 -o $uo1 -G $uparam
		ssrmsg=`python mujson_mgr.py -l -u $uname | tail -n 1 | sed 's/^[ \t]*//g'`
		echo "#Test User information" >> ${log_file}
		echo "#The passwd = $upass" >> ${log_file}
		echo "#The URL = $ssrmsg" >> ${log_file}
	else
		echo "拒绝创建测试账号，退出"
		uadd="no"
	fi
}

rand(){
	min=1000
	max=$((2000-$min+1))
	num=$(date +%s%N)
	echo $(($num%$max+$min))
}

dothetest(){
    if [[ ! -e ${log_file} ]];then
	    echo "配置文件不存在"
        exit 1
    fi
	nowdate=`date '+%Y-%m-%d %H:%M:%S'`
	filesize=`ls -l $log_file | awk '{ print $5 }'`
	#email=`cat ${log_file} | head -n 6 | tail -n 1 | awk -F" = " '{ print $2 }'`
	echo -e "========== 开始记录测试信息[$(date '+%Y-%m-%d %H:%M:%S')] ==========\n" >> ${log_file}
	if [ $filesize -gt $maxsize ];then
		echo "日志文件大小已达到上限，开始自动转储！" | tee -a ${log_file}
		tar -cjf servercheck"`date +%Y-%m-%d_%H:%M:%S`".tar.bz2 $log_file
		logset=`cat ${log_file} | head -n 5`
		rm -f ${log_file}
		echo "$logset" >> ${log_file}
		echo -e "========== 开始记录测试信息[$(date '+%Y-%m-%d %H:%M:%S')] ==========\n" >> ${log_file}
		echo "转储完成!"
	fi
	PID=$(ps -ef |grep -v grep | grep "server.py" | awk '{print $2}')
	if [[ -z ${PID} ]]; then
		echo "检测服务失败" | tee -a ${log_file}
		echo "服务开始重启" | tee -a ${log_file}
		export SSRcheck=Error
		#echo "检测到服务器在${nowdate}有一次异常记录，具体请查看日志:${log_file}" | mutt -s "[Warning]SSR-Bash-Python" ${email}
		bash /usr/local/shadowsocksr/stop.sh
		bash /usr/local/shadowsocksr/logrun.sh
		iptables-restore < /etc/iptables.up.rules
		echo "服务重启完成" | tee -a ${log_file}
	else
		echo "检测服务完成" | tee -a ${log_file}
	    passwd=`cat ${log_file} | head -n 2 | tail -n 1 | awk -F" = " '{ print $2 }'`
		rm -f ${state_file}
		echo "启动本地测试" | tee -a ${log_file}
	    nohup python "${ssr_local}/local.py" -b "127.0.0.1" -l "${local_port}" -p "${uport}" -k "${passwd}" -m "${um1}" -O "${ux1}" -o "${uo1}" >> ${state_file} 2>&1 &
		sleep 2s
		PID=$(ps -ef |grep -v grep | grep "local.py" | grep "${local_port}" | awk '{print $2}')
		if [[ -z ${PID} ]]; then
		    echo "本地测试启动失败" | tee -a ${log_file}
		    export SSRcheck=Error
		else
		    echo "本地测试启动成功" | tee -a ${log_file}
			echo "连接测试开始" | tee -a ${log_file}
			Test_results=$(curl --socks5 127.0.0.1:${local_port} -k -m ${Timeout} -s "${test_URL}")
			sleep 2s
			if [[ -z ${Test_results} ]];then
			    echo "第一次连接失败，重试!" | tee -a ${log_file}
			    sleep 2s
			    Test_results=$(curl --socks5 127.0.0.1:${local_port} -k -m ${Timeout} -s "${test_URL}")
				sleep 2s
				if [[ -z ${Test_results} ]];then
					echo "第二次连接失败，重试!" | tee -a ${log_file}
					sleep 2s
					Test_results=$(curl --socks5 127.0.0.1:${local_port} -k -m ${Timeout} -s "${test_URL}")
					sleep 2s
					if [[ -z ${Test_results} ]];then
						echo "第三次连接失败,开始重启服务" | tee -a ${log_file}
						bash /usr/local/shadowsocksr/stop.sh
						bash /usr/local/shadowsocksr/logrun.sh
						iptables-restore < /etc/iptables.up.rules
						echo "服务已重启!" | tee -a ${log_file}
						sleep 2s
						Test_results=$(curl --socks5 127.0.0.1:${local_port} -k -m ${Timeout} -s "${test_URL}")
						sleep 2s
						if [[ -z ${Test_results} ]];then
							export SSRcheck=Error
							echo "连接失败!" | tee -a ${log_file}
						else
							echo "连接成功！" | tee -a ${log_file}
						fi
					else
						echo "连接成功！" | tee -a ${log_file}
					fi
				else
					echo "连接成功！" | tee -a ${log_file}
				fi
			else
				echo "连接成功！" | tee -a ${log_file}
			fi
			echo "连接测试结束" | tee -a ${log_file}
		fi
		kill -9 ${PID}
		echo "结束本地测试" | tee -a ${log_file}
	fi
	echo -e "========== 记录测试信息结束[$(date '+%Y-%m-%d %H:%M:%S')] ==========\n\n" >> ${log_file}
}

main(){
if [[ ! -e ${log_file} ]];then
	mades
	if [[ $uadd == no ]];then
		exit 1
	fi
	while :;do echo 
	echo "请输入每次检测的间隔时间(单位：分)[默认30]:"
		read everytime
		if [[ -z ${everytime} ]];then
			everytime="30"
			break
		elif [[ ! ${everytime} =~ ^(-?|\+?)[0-9]+(\.?[0-9]+)?$ ]];then
			echo "请输入正确的数字"
		else
			break
		fi
	done
	echo "#The Time = ${everytime}m" >> ${log_file}
	echo "#############################################" >> ${log_file}
	if [[ ${values} == 1 ]];then
	    main
		exit 0
	fi
else
	thetime=`cat ${log_file} | head -n 4 | tail -n 1 | awk -F" = " '{ print $2 }'`
	if [[ -z ${thetime} ]];then
		rm -f ${log_file}
		main
		exit 1
	fi
	dothetest
	sleep ${thetime}
fi
}

runloop(){
    echo -e "========== 服务已启动      [$(date '+%Y-%m-%d %H:%M:%S')]==========\n\n" >> ${log_file}
	while :
	do
		if [[ -e ${log_file} ]];then
			main
		else
			echo "尚未配置，退出"
			echo -e "========== 服务已停止      [$(date '+%Y-%m-%d %H:%M:%S')]==========\n\n" >> ${log_file}
			break
		fi
	done
}

#Main
if [[ $1 == "" ]];then
	echo "Power BY Stack GitHub:https://github.com/readour"
	echo "========================================="
	echo -e "You can running\e[32;49m servercheck.sh conf \e[0mto configure the program.\nAfter they run you should run\e[32;49m nohup servercheck.sh running \e[0mto hang up it."
	echo -e "If you want to stop running this program.You should running \e[32;49m servercheck.sh stop \e[0m to stop it."
fi
if [[ $1 == stop ]];then
	PID=$(ps -ef |grep -v grep | grep "bash" | grep "servercheck.sh" | grep "run" | awk '{print $2}')
	if [[ -z ${PID} ]];then
		echo "进程不存在，程序未运行或者已经结束"
	else
		kill -9 ${PID}
		PID=$(ps -ef |grep -v grep | grep "bash" | grep "servercheck.sh" | grep "run" | awk '{print $2}')
		if [[ -z ${PID} ]];then
			echo "程序已经停止工作"
		else
			echo "结束失败"
		fi
	fi
	echo -e "========== 服务已停止      [$(date '+%Y-%m-%d %H:%M:%S')]==========\n" >> ${log_file}
fi
if [[ $1 == hide ]];then
	values="1"
	nohup bash /usr/local/SSR-Bash-Python/servercheck.sh run
fi
if [[ $1 == run ]];then
	values="1"
	runloop
fi
if [[ $1 == conf ]];then
	main
fi
if [[ $1 == reconf ]];then
	rm -f ${log_file}
	main
fi
if [[ $1 == log ]];then
	cat ${log_file}
	exit 0
fi
if [[ $1 == test ]];then
	PID=$(ps -ef |grep -v grep | grep "server.py" | awk '{print $2}')
	if [[ -z ${PID} ]];then
		dothetest
	else
		sleep 5s
		dothetest
	fi
fi