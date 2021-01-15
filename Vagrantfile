# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'yaml'

vms_config_file = File.expand_path('config/vms.yaml', __dir__)
vms_config      = YAML.load_file(vms_config_file)


Vagrant.configure('2') do |config|
  config.vagrant.plugins = ["vagrant-hosts"]
  vms_config['nodes'].each do |node|
    config.vm.define node['hostname'] do |n|
      n.vm.box      = node['box']
      n.vm.hostname = node['hostname']
      n.vm.network :private_network, ip: node['ip']

      n.vm.provider :virtualbox do |vb|
        vb.memory = node['memory']
      end

      n.vm.provision :shell, path: 'provision/shell/install_common.sh'
      n.vm.provision :shell, path: node['config_script']
      n.vm.provision :hosts do |p|
        vms_config['nodes'].each do |entry|
          p.add_host entry['ip'], [entry['hostname']]
        end
      end
    end
  end
end
