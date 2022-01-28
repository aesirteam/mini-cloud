#!/bin/bash
set -eux

yum install -y targetcli lvm2

IQN=iqn.1993-08.org.debian:01:7747bbc5bef3

if test -b /dev/vdb; then
  parted /dev/vdb mklabel msdos
  parted /dev/vdb mkpart primary 1 100% 
  pvcreate /dev/vdb1
  vgcreate vg00 /dev/vdb1
  lvcreate -l 100%FREE -n lvsan1 vg00
  targetcli /backstores/block create dev=/dev/vg00/lvsan1 name=sanblock1 
  #targetcli /iscsi set discovery_auth enable=1 userid=$DISCOVERY_USERNAME password=$DISCOVERY_PASSWORD
  targetcli /iscsi create $IQN
  targetcli /iscsi/$IQN/tpg1/portals delete 0.0.0.0 3260
  targetcli /iscsi/$IQN/tpg1/portals create $1
  
  targetcli /iscsi/$IQN/tpg1/luns create /backstores/block/sanblock1 
  targetcli /iscsi/$IQN/tpg1/acls create $IQN
  # targetcli /iscsi/$IQN/tpg1/acls/$IQN set auth userid=$NODE_USERNAME password=$NODE_PASSWORD
  systemctl enable target
  systemctl start target
fi