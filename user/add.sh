#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin


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


#Check Root
[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }


echo "你选择了添加用户"
echo ""
read -p "输入用户名： " uname
if [[ $uname == "" ]]; then
	bash /usr/local/SSR-Bash-Python/user.sh || exit 0
fi
read -p "输入端口： " uport
read -p "输入密码： " upass
echo ""
echo "加密方式"
echo '1.none'
echo '2.aes-128-cfb'
echo '3.aes-256-cfb'
echo '4.aes-128-ctr'
echo '5.aes-256-ctr'
echo '6.rc4-md5'
echo '7.chacha20'
echo '8.chacha20-ietf'
echo '9.salsa20'
while :; do echo
	read -p "输入加密方式： " um
	if [[ ! $um =~ ^[1-9]$ ]]; then
		echo "输入错误! 请输入正确的数字!"
	else
		break	
	fi
done


echo "协议方式"
echo '1.origin'
echo '2.auth_sha1_v4'
echo '3.auth_aes128_md5'
echo '4.auth_aes128_sha1'
echo '5.verify_deflate'
echo '6.auth_chain_a'
echo '7.auth_chain_b'
echo '8.auth_chain_c'
echo '9.auth_chain_d'
echo '10.auth_chain_e'
while :; do echo
	read -p "输入协议方式： " ux
	if [[ ! $ux =~ ^[1-9]$ ]]; then
		if [[ $ux == 10 ]]; then
			break
		fi
		echo "输入错误! 请输入正确的数字!"
	else
		break	
	fi
done

if [[ $ux == 2 ]];then
	while :; do echo
		read -p "是否兼容原版协议（y/n）： " ifprotocolcompatible
		if [[ ! $ifprotocolcompatible =~ ^[y,n]$ ]]; then
			echo "输入错误! 请输入y或者n!"
		else
			break
		fi
	done
fi

if [[ ! $ux =~ ^[1,5]$ ]]; then
	if [[ ! $ifprotocolcompatible == "y" ]]; then
		while :; do echo 
			read -p "请输入连接数限制(建议最少 2个): " uparam
			if [[ ! $uparam =~ ^(-?|\+?)[0-9]+(\.?[0-9]+)?$ ]]; then
				echo "输入错误! 请输入正确的数字!"
			else
				break
			fi
		done
	fi
fi

echo "混淆方式"
echo '1.plain'
echo '2.http_simple'
echo '3.http_post'
echo '4.tls1.2_ticket_auth'
while :; do echo
	read -p "输入混淆方式： " uo
	if [[ ! $uo =~ ^[1-4]$ ]]; then
		echo "输入错误! 请输入正确的数字!"
	else
		break	
	fi
done

if [[ $uo != 1 ]];then
	while :; do echo
		read -p "是否兼容原版混淆（y/n）： " ifobfscompatible
		if [[ ! $ifobfscompatible =~ ^[y,n]$ ]]; then
			echo "输入错误! 请输入y或者n!"
		else
			break
		fi
	done
fi


if [[ $um == 1 ]];then
	um1="none"
fi
if [[ $um == 2 ]];then
	um1="aes-128-cfb"
fi
if [[ $um == 3 ]];then
	um1="aes-256-cfb"
fi
if [[ $um == 4 ]];then
	um1="aes-128-ctr"
fi
if [[ $um == 5 ]];then
	um1="aes-256-ctr"
fi
if [[ $um == 6 ]];then
	um1="rc4-md5"
fi
if [[ $um == 7 ]];then
	um1="chacha20"
fi
if [[ $um == 8 ]];then
	um1="chacha20-ietf"
fi
if [[ $um == 9 ]];then
	um1="salsa20"
fi

if [[ $ux == 1 ]];then
	ux1="origin"
fi
if [[ $ux == 2 ]];then
	ux1="auth_sha1_v4"
fi
if [[ $ux == 3 ]];then
	ux1="auth_aes128_md5"
fi
if [[ $ux == 4 ]];then
	ux1="auth_aes128_sha1"
fi
if [[ $ux == 5 ]];then
	ux1="verify_deflate"
fi

if [[ $ux == 6 ]];then
	ux1="auth_chain_a"
fi
if [[ $ux == 7 ]];then
	ux1="auth_chain_b"
fi

if [[ $ux == 8 ]];then
	ux1="auth_chain_c"
fi
if [[ $ux == 9 ]];then
	ux1="auth_chain_d"
fi

if [[ $ux == 10 ]];then
	ux1="auth_chain_e"
fi

if [[ $uo == 1 ]];then
	uo1="plain"
fi
if [[ $uo == 2 ]];then
	uo1="http_simple"
fi
if [[ $uo == 3 ]];then
	uo1="http_post"
fi
if [[ $uo == 4 ]];then
	uo1="tls1.2_ticket_auth"
fi

if [[ $ifobfscompatible == y ]]; then
	uo1=${uo1}"_compatible"
fi

if [[ $ifprotocolcompatible == y ]]; then
	ux1=${ux1}"_compatible"
fi

while :; do echo
	read -p "输入流量限制(只需输入数字，单位：GB)： " ut
	if [[ "$ut" =~ ^(-?|\+?)[0-9]+(\.?[0-9]+)?$ ]];then
	   break
	else
	   echo 'Input Error!'
	fi
done

while :; do echo
	read -p "是否开启端口限速（y/n）： " iflimitspeed
	if [[ ! $iflimitspeed =~ ^[y,n]$ ]]; then
		echo "输入错误! 请输入y或者n!"
	else
		break
	fi
done

if [[ $iflimitspeed == y ]]; then
	while :; do echo
		read -p "输入端口总限速(只需输入数字，单位：KB/s)： " us
		if [[ "$us" =~ ^(-?|\+?)[0-9]+(\.?[0-9]+)?$ ]];then
	   		break
		else
	   		echo 'Input Error!'
		fi
	done
fi

while :; do
	read -p "是否需要限制帐号有效期(y/n): " iflimittime
	if [[ ! ${iflimittime} =~ ^[y,n]$ ]]; then
		echo "输入错误! 请输入y或者n!"
	else
		break
	fi
done

if [[ ${iflimittime} == y ]]; then
	read -p "请输入有效期(单位：月[m]日[d]小时[h],例如：1个月就输入1m){默认：一个月}: " limit
	if [[ -z ${limit} ]];then
		limit="1m"
	fi
	bash /usr/local/SSR-Bash-Python/timelimit.sh a ${uport} ${limit}
	datelimit=$(cat /usr/local/SSR-Bash-Python/timelimit.db | grep "${uport}:" | awk -F":" '{ print $2 }' | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9}\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1年\2月\3日 \4:/')
fi
if [[ -z ${datelimit} ]]; then
	datelimit="永久"
fi

#Set Firewalls
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

#Run ShadowsocksR
echo "用户添加成功！用户信息如下："
cd /usr/local/shadowsocksr

if [[ $iflimitspeed == y ]]; then
	if [[ ! "$uparam" == "" ]]; then
		python mujson_mgr.py -a -u $uname -p $uport -k $upass -m $um1 -O $ux1 -o $uo1 -t $ut -S $us -G $uparam
	else
		python mujson_mgr.py -a -u $uname -p $uport -k $upass -m $um1 -O $ux1 -o $uo1 -t $ut -S $us
		uparam="无限"
	fi
else
	if [[ ! "$uparam" == "" ]]; then
		python mujson_mgr.py -a -u $uname -p $uport -k $upass -m $um1 -O $ux1 -o $uo1 -t $ut -G $uparam
	else
		python mujson_mgr.py -a -u $uname -p $uport -k $upass -m $um1 -O $ux1 -o $uo1 -t $ut
		uparam="无限"
	fi
fi

SSRPID=$(ps -ef | grep 'server.py m' | grep -v grep | awk '{print $2}')
if [[ -z ${SSRPID} ]];then 
	if [[ ${OS} =~ ^Ubuntu$|^Debian$ ]];then
		iptables-restore < /etc/iptables.up.rules
	fi
    bash /usr/local/shadowsocksr/logrun.sh
	echo "ShadowsocksR服务器已启动"
fi
myipname=`cat /usr/local/shadowsocksr/myip.txt`
echo "你可以复制以下信息给你的用户: "
echo "===================="
echo "用户名: $uname"
echo "服务器地址: $myipname"
echo "远程端口号: $uport"
echo "本地端口号: 1080"
echo "密码: $upass"
echo "加密方法: $um1"
echo "协议: $ux1"
echo "混淆方式: $uo1"
echo "流量: $ut GB"
echo "允许连接数: $uparam"
echo "帐号有效期: $datelimit"
echo "===================="
echo ""
echo "是否需要为该用户生成二维码？（y/n）"
read -n 1 cyn
if [[ $cyn == [yY] ]];then
	bash /usr/local/SSR-Bash-Python/user/qrcode.sh u $uname
fi