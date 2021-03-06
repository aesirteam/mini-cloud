#!/bin/bash
set -e

if [ ! -d "ceph-ansible" ]; then
	git clone https://github.com/ceph/ceph-ansible.git -b stable-5.0 -q
fi

if [ ! -f "ceph-ansible/site.yml" ]; then
	cp ceph-ansible/site.yml.sample ceph-ansible/site.yml
fi

cat <<-'EOF' > ceph-ansible/group_vars/all.yml
dummy:
cluster: ceph
configure_firewall: false
ceph_origin: repository
ceph_repository: community
ceph_mirror: http://mirrors.163.com/ceph
ceph_stable_key: http://mirrors.163.com/ceph/keys/release.asc
ceph_stable_release: octopus
ceph_stable_repo: "{{ ceph_mirror }}/rpm-{{ ceph_stable_release }}"
nfs_ganesha_stable: true
nfs_ganesha_stable_branch: V3.3-stable
nfs_ganesha_stable_deb_repo: "{{ ceph_mirror }}/nfs-ganesha/rpm-{{ nfs_ganesha_stable_branch }}/{{ ceph_stable_release }}"
monitor_interface: eth1
public_network: 10.20.20.0/24
cluster_network: 172.18.0.0/24
osd_objectstore: bluestore
radosgw_interface: eth1
radosgw_civetweb_port: 8080
radosgw_frontend_port: "{{ radosgw_civetweb_port if radosgw_frontend_type == 'civetweb' else '8080' }}"
ceph_conf_overrides:
  global:
    auth_allow_insecure_global_id_reclaim: false
    auth_expose_insecure_global_id_reclaim: false
    mon_warn_on_insecure_global_id_reclaim_allowed: false
    mon_allow_pool_size_one: true
    mon_allow_pool_delete: true
    mon_warn_on_pool_no_redundancy: false
    osd_pool_default_size: 2
    mon_max_pg_per_osd: 300
dashboard_port: 8443
dashboard_admin_password: password
grafana_port: 3000
grafana_admin_password: password
EOF

cat <<-EOF > ceph-ansible/group_vars/osds.yml
dummy:
devices:
  - /dev/vdb
#bluestore_wal_devices:
#  - /dev/nvme0n1
#  - /dev/nvme0n2
EOF
