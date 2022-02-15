# -*- mode: ruby -*-
# vi: set ft=ruby :

load "config.rb"

Vagrant.configure("2") do |config|
	config.ssh.insert_key = false
	config.vm.box_check_update = false
	config.vm.synced_folder '.', '/vagrant', disabled: true

	config.vm.provider :libvirt do |lv|
		lv.management_network_name = 'default'
		lv.management_network_address = '192.168.122.0/24'
		# lv.management_network_mode = 'nat'
		lv.management_network_keep = true

		lv.default_prefix = ''
		lv.graphics_type = 'none'
	end

	if Vagrant.has_plugin?("vagrant-proxyconf")
		config.proxy.http = "http://192.168.122.1:8888/"
		config.proxy.https = "http://192.168.122.1:8888/"
		config.proxy.no_proxy = "localhost,127.0.0.1,::1"
	end

    config.trigger.before :up do |t|
		t.run = {path: 'scripts/ceph-ansible.sh'}
	end

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
			    lv.machine_virtual_size = node[:disk] if !node[:disk]

			    lv.storage :file, :size => node[:storage], :path => "#{node[:name]}_osd.img", :type => 'qcow2', :cache => 'none' if !node[:storage]
			end

			srv.vm.provision :shell, path: 'scripts/prepare.sh', args: [node[:name], node[:eth1], node[:eth2]]
			srv.vm.provision :shell, path: 'scripts/provision.sh'
		end
    end

    $ceph.each do |node|
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

 #    if Vagrant.has_plugin?("vagrant-proxyconf")
	# 	config.proxy.enabled = false
	# end

    config.group.groups = $groups
end
