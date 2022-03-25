# -*- mode: ruby -*-
# vi: set ft=ruby :

load "config.rb"

Vagrant.configure("2") do |config|
	config.ssh.insert_key = false
	config.vm.box_check_update = false
	config.vm.synced_folder '.', '/vagrant', disabled: true
	
	config.vm.provider :libvirt do |lv|
		lv.management_network_name = 'mgmt'
		lv.management_network_address = '192.168.0.0/24'
		lv.management_network_mode = 'none'

		lv.cpu_mode = 'host-passthrough'
	    lv.nested = true
	    lv.keymap = 'pt'

		lv.default_prefix = ''
		lv.graphics_type = 'none'
	end

    $pve.each do |node|
        config.vm.define node[:name] do |srv|
		    srv.vm.box = "aesirteam/proxmox-ve-amd64"
	  	    # srv.vm.box_version = "7.1"
			srv.vm.hostname = node[:name]
	  	    
		    srv.vm.network :private_network, ip: node[:eth1], auto_config: false,
		        libvirt__network_name: 'pve_cluster',
				libvirt__dhcp_enabled: true,
				libvirt__forward_mode: 'nat',
				libvirt__dhcp_start: '10.10.10.10',
				libvirt__dhcp_end: '10.10.10.254'

			srv.vm.network :private_network, ip: node[:eth2], auto_config: false,
			    libvirt__network_name: 'storage_network',
			    libvirt__dhcp_enabled: false,
			    libvirt__forward_mode: 'none'

			srv.vm.network :public_network, :dev => 'br0', :type => 'bridge', :mode => 'bridge' 

			srv.vm.provider :libvirt do |lv|
				lv.machine_type = 'pc-q35-focal'
			    lv.memory = node[:ram]
			    lv.cpus = node[:vcpu]
			    lv.machine_virtual_size = 20
			    lv.storage :file, :size => node[:storage], :path => "#{node[:name]}_osd.img", :type => 'qcow2', :cache => 'none' if node[:storage]
			end

			srv.vm.provision :shell, :args => $proxy, inline: <<-SHELL
				ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
				echo GenerateName=yes > /etc/iscsi/initiatorname.iscsi

				proxy=${1:-}
				if [ ! -z $proxy ]; then
					cat > /etc/apt/apt.conf.d/17proxy <<-EOF
					Acquire::http::proxy "$proxy";
					Acquire::https::proxy "$proxy";
					EOF
				fi
			SHELL

			srv.vm.provision :shell, path: 'scripts/provision.sh', args: [node[:eth1], node[:eth2]], reboot: true
		end
    end

    $ceph.each do |node|
    	config.vm.define node[:name] do |srv|
           	srv.vm.box =  'centos/stream8'
    		srv.vm.hostname = node[:name]

			srv.trigger.before :up do |t|
				t.run = {path: 'scripts/ceph-ansible.sh'}
			end

    	   	srv.vm.network :private_network, ip: node[:eth1],
    	   		libvirt__network_name: 'storage_network',
	       		libvirt__dhcp_enabled: false,
	       		libvirt__forward_mode: 'none'

			srv.vm.network :private_network, ip: node[:eth2],
				libvirt__network_name: 'ceph_cluster',
				libvirt__dhcp_enabled: false,
				libvirt__forward_mode: 'none'
			
			srv.vm.network :public_network, :dev => 'br0', :type => 'bridge', :mode => 'bridge' 

	    	srv.vm.provider :libvirt do |lv|
	    		lv.memory = node[:ram]
	        	lv.cpus = node[:vcpu]
	        	lv.storage :file, :size => node[:storage], :path => "#{node[:name]}_osd.img", :type => 'qcow2', :cache => 'none'
			end

			srv.vm.provision :shell, :args => $proxy, inline: <<-SHELL
				ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
				setenforce 0
				sed -i 's/enforcing/disabled/g' /etc/selinux/config
				
				sed -i -e "s|mirrorlist=|#mirrorlist=|g" /etc/yum.repos.d/CentOS-*
				sed -i -e "s|#baseurl=http://mirror.centos.org|baseurl=http://mirrors.163.com|g" /etc/yum.repos.d/CentOS-*
				
				proxy=${1:-}
				if [ ! -z $proxy ]; then
					sed -i "/proxy=/d" /etc/dnf/dnf.conf
					echo proxy=$proxy  >> /etc/dnf/dnf.conf

					cat > /etc/environment <<-EOF
					http_proxy=$proxy
					https_proxy=$proxy
					no_proxy=localhost,127.0.0.1,::1
					EOF
				fi
			SHELL

   			srv.vm.provision :ansible do |ansible|
				ansible.config_file = 'ceph-ansible/ansible.cfg'
	    		ansible.playbook = 'ceph-ansible/site.yml'
				ansible.groups = {
					:mons => $groups['ceph'],
					:osds => $groups['ceph'],
					:mdss => $groups['ceph'],
					:rgws => $groups['ceph'],
					:iscsigws => $groups['ceph'],
					:nfss => $groups['ceph'],
					:mgrs => $groups['ceph'],
					'grafana-server' => $groups['ceph'].first,
					:clients => $groups['ceph'].first
				}
				ansible.limit = 'all'
			end if (node == $ceph.last)
       end 
    end

    config.group.groups = $groups
end
