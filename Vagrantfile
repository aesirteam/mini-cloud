# -*- mode: ruby -*-
# vi: set ft=ruby :

load "config.rb"

Vagrant.configure("2") do |config|
	config.ssh.insert_key = false
	config.vm.box_check_update = false
	config.vm.synced_folder '.', '/vagrant', disabled: true

	config.proxy.http = "http://192.168.122.1:8888"
	config.proxy.https = "http://192.168.122.1:8888"
	config.proxy.no_proxy = "localhost,127.0.0.1,::1"

    
	config.vm.provider :libvirt do |lv|
		lv.management_network_name = 'mgmt'
		lv.management_network_address = '192.168.121.0/24'
		lv.management_network_mode = 'nat'
		lv.default_prefix = ''
		lv.graphics_type = 'none'
	end

    $groups['cluster'].each_with_index do |node,i|
        config.vm.define node do |srv|
		    srv.vm.box = "aesirteam/proxmox-ve-amd64"
	  	    srv.vm.box_version = "6.4"
	  	    
	  	    ip = "10.10.10.#{i+10}"
		    srv.vm.network :private_network, ip: ip, auto_config: false,
		        libvirt__network_name: 'pve_cluster',
				libvirt__dhcp_enabled: false,
				libvirt__forward_mode: 'none'
				
			ip1 = "10.20.20.#{i+10}"
			srv.vm.network :private_network, ip: ip1, auto_config: false,
			    libvirt__network_name: 'storage_network',
			    libvirt__dhcp_enabled: false,
			    libvirt__forward_mode: 'none'

			srv.vm.provider :libvirt do |lv|
			    lv.memory = $cluster_vars[:ram]
			    lv.cpus = $cluster_vars[:vcpu]
			    lv.cpu_mode = 'host-passthrough'
			    lv.nested = true
			    lv.keymap = 'pt'
			    lv.machine_virtual_size = $cluster_vars[:disk]

			    if $cluster_vars[:storage] != nil
			    	lv.storage :file, :size => $cluster_vars[:storage], :path => "#{node}_osd.img", :type => 'qcow2', :cache => 'none'
			    end
			end

			srv.vm.provision :shell, path: 'scripts/prepare.sh', args: [node, 'cluster']
			srv.vm.provision :shell, path: 'scripts/provision.sh', args: [ip, ip1]
			srv.vm.provision :shell, path: 'scripts/provision-pveproxy-certificate.sh', args: ip
	  		srv.vm.provision :shell, path: 'scripts/summary.sh', args: ip
		end
    end

    $groups['storage'].each_with_index do |node,i|
    	config.vm.define node do |srv|
           	srv.vm.box = "centos/8"
    		
    		ip = "10.20.20.#{i+30}"
    	   	srv.vm.network :private_network, ip: ip,
    	   		libvirt__network_name: 'storage_network',
	       		libvirt__dhcp_enabled: false,
	       		libvirt__forward_mode: 'none'

			ip = "172.18.0.#{i+10}"
			srv.vm.network :private_network, ip: ip,
				libvirt__network_name: 'ceph_cluster',
				libvirt__dhcp_enabled: false,
				libvirt__forward_mode: 'none'
	       
	    	srv.vm.provider :libvirt do |lv|
	    		lv.memory = $storage_vars[:ram]
	        	lv.cpus = $storage_vars[:vcpu]
	        	lv.cpu_mode = 'host-passthrough'
	        	lv.nested = true
	        	lv.keymap = 'pt'
	        	lv.storage :file, :size => $storage_vars[:storage], :path => "#{node}_osd.img", :type => 'qcow2', :cache => 'none'
			end

			srv.vm.provision :shell, path: 'scripts/prepare.sh', args: [node, 'storage']

			if i == 0
    			srv.trigger.before :up do |trigger|
    				trigger.run = {path: 'scripts/ceph-ansible.sh'}
    			end
    		end

			if i ==  $groups['storage'].length()-1
	   			srv.vm.provision :ansible do |ansible|
					ansible.config_file = 'ceph-ansible/ansible.cfg'
		    		ansible.playbook = 'ceph-ansible/site.yml'
					ansible.groups = {
						:mons => $groups['storage'],
						:osds => $groups['storage'],
						:mdss => $groups['storage'],
						:rgws => $groups['storage'],
						:iscsigws => $groups['storage'],
						:mgrs => $groups['storage'],
						'grafana-server' => ['ceph-node1'],
						:clients => ['ceph-node1']
					}
					ansible.limit = 'all'
				end
			end
       end 
    end

    config.group.groups = $groups
end
