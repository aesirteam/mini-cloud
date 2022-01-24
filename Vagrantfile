# -*- mode: ruby -*-
# vi: set ft=ruby :

load "config.rb"

Vagrant.configure("2") do |config|
	config.ssh.insert_key = false
	config.vm.box_check_update = false
	config.vm.synced_folder '.', '/vagrant', disabled: true

	config.vm.provider :libvirt do |lv|
		lv.management_network_name = 'mgmt'
		lv.management_network_address = '192.168.121.0/24'
		lv.management_network_mode = 'nat'
		lv.default_prefix = ''
		lv.graphics_type = 'none'
	end

	config.proxy.http = "http://192.168.121.1:8888"
	config.proxy.https = "http://192.168.121.1:8888"
	config.proxy.no_proxy = "localhost,127.0.0.1,::1"

    $pve.each do |node|
        config.vm.define node[:name] do |srv|
		    srv.vm.box = "aesirteam/proxmox-ve-amd64"
	  	    srv.vm.box_version = "6.4"
	  	    
		    srv.vm.network :private_network, ip: node[:eth1], auto_config: false,
		        libvirt__network_name: 'pve_cluster',
				libvirt__dhcp_enabled: false,
				libvirt__forward_mode: 'none'
				
			srv.vm.network :private_network, ip: node[:eth2], auto_config: false,
			    libvirt__network_name: 'storage_network',
			    libvirt__dhcp_enabled: false,
			    libvirt__forward_mode: 'none'

			srv.vm.provider :libvirt do |lv|
			    lv.memory = node[:ram]
			    lv.cpus = node[:vcpu]
			    lv.cpu_mode = 'host-passthrough'
			    lv.nested = true
			    lv.keymap = 'pt'
			    lv.machine_virtual_size = node[:disk]

			    if node[:storage] != nil
			    	lv.storage :file, :size => node[:storage], :path => "#{node[:name]}_osd.img", :type => 'qcow2', :cache => 'none'
			    end
			end

			srv.vm.provision :shell, path: 'scripts/prepare.sh', args: [node[:name], node[:eth1], node[:eth2]]
			srv.vm.provision :shell, path: 'scripts/provision.sh'
			srv.vm.provision :shell, path: 'scripts/provision-pveproxy-certificate.sh'
	  		srv.vm.provision :shell, path: 'scripts/summary.sh'
		end
    end

    $ceph.each_with_index do |node,i|
    	config.vm.define node[:name] do |srv|
           	srv.vm.box = "centos/8"
    		
    	   	srv.vm.network :private_network, ip: node[:eth1],
    	   		libvirt__network_name: 'storage_network',
	       		libvirt__dhcp_enabled: false,
	       		libvirt__forward_mode: 'none'

			srv.vm.network :private_network, ip: node[:eth2],
				libvirt__network_name: 'ceph_cluster',
				libvirt__dhcp_enabled: false,
				libvirt__forward_mode: 'none'
	       
	    	srv.vm.provider :libvirt do |lv|
	    		lv.memory = node[:ram]
	        	lv.cpus = node[:vcpu]
	        	lv.cpu_mode = 'host-passthrough'
	        	lv.nested = true
	        	lv.keymap = 'pt'
	        	lv.storage :file, :size => node[:storage], :path => "#{node[:name]}_osd.img", :type => 'qcow2', :cache => 'none'
			end

			srv.vm.provision :shell, path: 'scripts/prepare.sh', args: node[:name]

			if i == 0
    			srv.trigger.before :up do |trigger|
    				trigger.run = {path: 'scripts/ceph-ansible.sh'}
    			end
    		end

			if (i+1) ==  $ceph.length()
	   			srv.vm.provision :ansible do |ansible|
					ansible.config_file = 'ceph-ansible/ansible.cfg'
		    		ansible.playbook = 'ceph-ansible/site.yml'
					ansible.groups = {
						:mons => $groups['ceph'],
						:osds => $groups['ceph'],
						:mdss => $groups['ceph'],
						:rgws => $groups['ceph'],
						:iscsigws => $groups['ceph'],
						:mgrs => $groups['ceph'],
						'grafana-server' => $groups['ceph'].take(1),
						:clients => $groups['ceph'].take(1)
					}
					ansible.limit = 'all'
				end
			end
       end 
    end

    config.group.groups = $groups
end
