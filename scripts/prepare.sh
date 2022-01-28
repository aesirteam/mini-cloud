#!/bin/bash

hostnamectl --static set-hostname $1

if [[ $1 =~ ^pve.* ]]; then
  sed -i "s/pve/$1/g" /etc/hosts
  sed -i "s/pve/$1/g" /etc/postfix/main.cf

  echo "export PVE_CLUSTER_ADDR=$2" >> /etc/profile
  echo "export STORAGE_CLUSTER_ADDR=$3" >> /etc/profile

  echo GenerateName=yes > /etc/iscsi/initiatorname.iscsi
  systemctl restart iscsid
elif [[ $1 =~ ^ceph.* ]]; then
  setenforce 0
  sed -i 's/enforcing/disabled/g' /etc/selinux/config
fi

ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
