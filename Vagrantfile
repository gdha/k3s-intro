# -*- mode: ruby -*-
# vi: set ft=ruby :

#BOX = "generic/alpine39"
BOX = "bento/ubuntu-18.04"
HOME = File.dirname(__FILE__)
PROJECT = File.basename(HOME)

# --- Check for missing plugins
required_plugins = %w( vagrant-alpine vagrant-timezone )
plugin_installed = false
required_plugins.each do |plugin|
  unless Vagrant.has_plugin?(plugin)
    system "vagrant plugin install #{plugin}"
    plugin_installed = true
  end
end
# --- If new plugins installed, restart Vagrant process
if plugin_installed === true
  exec "vagrant #{ARGV.join' '}"
end

nodes = [
   { :hostname => 'k3s-master',  :ip => '192.168.33.11', :box => BOX, :ram => 1024, :cpus => 1 },
   { :hostname => 'k3s-client1', :ip => '192.168.33.12', :box => BOX, :ram => 1024, :cpus => 1 },
   { :hostname => 'k3s-client2', :ip => '192.168.33.13', :box => BOX, :ram => 1024, :cpus => 1 }
]

ENV['VAGRANT_DEFAULT_PROVIDER'] = 'virtualbox'

Vagrant.configure(2) do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  nodes.each do |node|
    config.vm.define node[:hostname] do |nodeconfig|
      nodeconfig.vm.box = node[:box]
      nodeconfig.vm.hostname = node[:hostname] + ".box"
      nodeconfig.vm.network :private_network, ip: node[:ip]
      nodeconfig.timezone.value = :host

      memory = node[:ram] ? node[:ram] : 256;
      host = node[:hostname]
      nodeconfig.vm.provider :virtualbox do |vb|
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.cpus = node[:cpus]
      end
     
      nodeconfig.vm.provision :shell, privileged: false do |s|
        s.inline = <<-SHELL
           sudo mkdir -p -m 755 /vagrant
           sudo apt-get -y install python
           sudo apt-get -y install ansible
           sudo apt-get -y install resolvconf
           mkdir -p -m 700 /home/$USER/.ssh
           rm -f /home/$USER/.ssh/id_rsa
           ssh-keygen -b 2048 -t rsa -f /home/$USER/.ssh/id_rsa -q -N ''
           cat /home/$USER/.ssh/id_rsa.pub >> /home/$USER/.ssh/authorized_keys
	SHELL
      end

      nodeconfig.vm.synced_folder ".", "/vagrant", disabled: false

      nodeconfig.vm.provision :shell, privileged: false do |s|
        s.inline = <<-SHELL
           #[[ -f /vagrant/hosts.ini ]] && sudo cp /vagrant/hosts.ini /etc/ansible/hosts
           [[ -f /vagrant/ansible/roles/prep/files/hosts ]] && sudo cp /vagrant/ansible/roles/prep/files/hosts /etc/hosts
           # sleep a bit to have network daemons up-and-running
           sleep 4
	SHELL
      end
      nodeconfig.vm.provision "ansible_local" do |ansible|
        ansible.compatibility_mode = "2.0"
        ansible.playbook = "/vagrant/ansible/site.yml"
        ansible.inventory_path  = "/vagrant/hosts.ini"
        ansible.become = true
        ansible.verbose = 'v'
      end
      nodeconfig.ssh.forward_agent    = true
      nodeconfig.ssh.insert_key       = false
      nodeconfig.ssh.private_key_path =  ["~/.vagrant.d/insecure_private_key","~/.ssh/id_rsa"]
      nodeconfig.vm.provision :shell, privileged: false do |s|
        ssh_pub_key = File.readlines("#{Dir.home}/.ssh/id_rsa.pub").first.strip
        s.inline = <<-SHELL
           echo #{ssh_pub_key} >> /home/$USER/.ssh/authorized_keys
           sudo bash -c "mkdir -p -m 700 /root/.ssh"
           sudo bash -c "echo #{ssh_pub_key} >> /root/.ssh/authorized_keys"
        SHELL
      end

    # end of config.vm.define node
    end
  # end of nodes.each do |node|
  end

#  nodes.each do |node|
#    config.vm.define node[:hostname] do |nodeconfig|
#      nodeconfig.vm.provision "ansible_local" do |ansible|
#        ansible.compatibility_mode = "2.0"
#        ansible.playbook = "/vagrant/ansible/site.yml"
#        ansible.inventory_path  = "/vagrant/hosts.ini"
#        ansible.become = true
#        ansible.verbose = 'v'
#      end
#    # end of config.vm.define node
#    end
#  # end of nodes.each do |node|
#  end

# end of Vagrant.configure
end 
