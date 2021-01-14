# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'yaml'

scenario_config_file = File.expand_path('config/default.yml', __dir__)
scenario_config      = YAML.load_file(scenario_config_file)

Vagrant.configure('2') do |config|

  config.vagrant.plugins = ["vagrant-proxyconf", "vagrant-hosts"]

  # It needs to be executed: vagrant plugins install vagrant-hosts
  config.vm.define scenario_config['devops']['hostname'] do |n|
    n.vm.box_check_update = false 
    n.vm.box      = scenario_config['devops']['box']
    n.vm.hostname = scenario_config['devops']['hostname']
    n.vm.network :private_network, ip: scenario_config['devops']['ip']

    n.vm.provider :virtualbox do |vb|
      vb.memory = '1024'
      vb.default_nic_type = "virtio"
    end

    n.vm.provision :shell, path: 'provision/shell/install_base.sh'
    n.vm.provision :hosts do |p|
      p.add_host scenario_config['devops']['ip'], [scenario_config['devops']['hostname']]
    end
  end

end
