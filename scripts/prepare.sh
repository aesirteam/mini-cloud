#!/bin/bash

hostnamectl --static set-hostname $1
ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

if [[ $1 =~ ^pve.* ]]; then
  sed -i "s/pve/$1/g" /etc/hosts
  sed -i "s/pve/$1/g" /etc/postfix/main.cf

  echo "export PVE_CLUSTER_ADDR=$2" >> /etc/profile
  echo "export STORAGE_CLUSTER_ADDR=$3" >> /etc/profile

  echo GenerateName=yes > /etc/iscsi/initiatorname.iscsi
  systemctl restart iscsid
elif [[ $1 =~ ^ceph.* ]]; then
  echo "export LC_ALL=C.UTF-8" >> /etc/profile

  setenforce 0
  sed -i 's/enforcing/disabled/g' /etc/selinux/config

  sed -i -e "s|mirrorlist=|#mirrorlist=|g" /etc/yum.repos.d/CentOS-*
  sed -i -e "s|#baseurl=http://mirror.centos.org|baseurl=http://mirrors.cloud.tencent.com|g" /etc/yum.repos.d/CentOS-*
fi

