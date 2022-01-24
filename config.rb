$groups = {'pve' => [], 'ceph' => []}

#network define:
#pve_cluster: 10.10.10.0/24
#storage_network: 10.20.20.0/24
#ceph_cluster: 172.18.0.0/24
$pve = [
	{
	    :name => 'pve-node1',
	    :vcpu => 8,
	    :ram => 16384,
	    :disk => 20,
		# :storage => '200G',
	    :eth1 => '10.10.10.10',
	    :eth2 => '10.20.20.100',
	},{
	    :name => "pve-node2",
	    :vcpu => 8,
	    :ram => 16384,
	    :disk => 20,
		# :storage => '200G',
	    :eth1 => '10.10.10.11',
	    :eth2 => '10.20.20.101',
	},{
	    :name => "pve-node3",
	    :vcpu => 8,
	    :ram => 16384,
	    :disk => 20,
		# :storage => '200G',
 		:eth1 => '10.10.10.12',
	    :eth2 => '10.20.20.102',
	}
]

$ceph = [
	{
	    :name => 'ceph-node1',
	    :vcpu => 4,
	    :ram => 4096,
	    # :disk => 20,
		:storage => '200G',
	    :eth1 => '10.20.20.30',
	    :eth2 => '172.18.0.10',
	},{
	    :name => "ceph-node2",
	    :vcpu => 4,
	    :ram => 4096,
	    # :disk => 20,
		:storage => '200G',
	    :eth1 => '10.20.20.31',
	    :eth2 => '172.18.0.11',
	},{
	    :name => "ceph-node3",
	    :vcpu => 4,
	    :ram => 4096,
	    # :disk => 20,
		:storage => '200G',
 		:eth1 => '10.20.20.32',
	    :eth2 => '172.18.0.12',
	}
]

$pve.each {|item| $groups['pve'].push(item[:name])}
$ceph.each {|item| $groups['ceph'].push(item[:name])}
