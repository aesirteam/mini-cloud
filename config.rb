$groups = {
	'cluster' => [
		'pve-node1',
		'pve-node2',
		'pve-node3'
	],
	'storage' => [
		'ceph-node1',
		'ceph-node2',
		'ceph-node3'
	],
}

$cluster_vars = {
	:vcpu => 8,
	:ram => 16384,
	:disk => 20,
	# :storage => '200G',
}


$storage_vars = {
	:vcpu => 2,
	:ram => 2048,
	:storage => '200G',
}