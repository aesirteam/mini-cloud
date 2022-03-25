#!/bin/bash

network_name=${1:-vagrant-libvirt}
bridge_name=${2:-br0}

virsh net-uuid $network_name > /dev/null 2>&1
if [ $? == 1 ]; then
	fn=`uuidgen -r`
	cat > $fn <<- EOF
	<network>
	<name>$network_name</name>
	<forward mode='bridge'/>
	<bridge name='$bridge_name'/>
	</network>
	EOF
	virsh net-define $fn
	virsh net-start $network_name
	rm -f $fn
fi
