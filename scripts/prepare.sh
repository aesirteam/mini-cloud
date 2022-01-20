#!/bin/bash

hostnamectl --static set-hostname $1

if [ -f /etc/selinux/config ]; then
  setenforce 0
  sed -i 's/enforcing/disabled/g' /etc/selinux/config
fi

# sed -i "s/pve\$/$1/" /etc/hosts
if [ -f /etc/postfix/main.cf ]; then 
  sed -i "s/pve/$1/g" /etc/hosts
  sed -i "s/pve/$1/g" /etc/postfix/main.cf
fi

ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

if [ $2 == "storage" ]; then
  yum update -y
elif [ $2 == "cluster" ]; then
  apt update
  apt upgrade -y
fi
