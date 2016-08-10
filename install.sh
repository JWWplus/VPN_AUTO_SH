#!/bin/bash

#阿里云/板瓦工VPN搭建脚本
echo "###################################"
echo "This script will configure PPTP VPN"
echo "###################################"

apt-get -y update &> /dev/null
apt-get install pptpd &>/dev/null

echo localip 192.168.10.1 >> /etc/pptpd.conf

echo remoteip 192.168.0.234-238,192.168.0.245 >> /etc/pptpd.conf

echo net.ipv4.ip_forward=1 >>/etc/sysctl.conf

rm -f /sbin/sysctl
ln -s /bin/true /sbin/sysctl
sysctl -p

# Set DNS
echo "ms-dns 8.8.8.8" >> /etc/ppp/pptpd-options
echo "ms-dns 8.8.4.4" >> /etc/ppp/pptpd-options 
#阿里云有2块网卡，第二块是外网
ip=ifconfig eth1 | grep "inet addr" | sed 's/^.*addr://g' | sed 's/Bcast.*//g'
#如果是其他运营商，那么使用下一条
#ifconfig | grep "inet addr" | sed 's/^.*addr://g' | sed 's/Bcast.*//g'


# Input username and password
echo "###################################"
echo "Please enter your new login details"
echo "###################################"
echo "Enter new username: "
read username
echo "Enter new password: "
read password

echo "$username    pptpd   $password  *" >> /etc/ppp/chap-secrets

#设置转发规则，阿里云和其他服务器略有不同
iptables -t nat -A POSTROUTING -s 192.168.0.0/24 -j SNAT –to-source $ip
iptables -t nat -A POSTROUTING -s 192.168.0.0/24 -o eth1 -j MASQUERADE
#非阿里云使用这一条 网卡不同
#iptables -t nat -A POSTROUTING -s 192.168.0.0/24 -o eth0 -j MASQUERADE

/etc/init.d/iptables save
service iptables restart
service pptpd restart

echo "############################"
echo "PPTP VPN Login Details"
echo "############################"
echo "Your IP is " $ip
echo "Your username is " $username
echo "Your password is " $password
echo "############################"

exit


