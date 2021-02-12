# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'yaml'

vms_config_sshkeys_path = File.expand_path('config/sshkeys', __dir__)

case ARGV[0]
when "provision", "up"
  if not (File.file?(vms_config_sshkeys_path + '/cluster_ssh_rsa.key'))
    system ("mkdir -p " + vms_config_sshkeys_path)
    system("ssh-keygen -t rsa -f " + vms_config_sshkeys_path + "/cluster_ssh_rsa.key -C vboxnode@k8s -N \"\"")
  else
    print "SSH key file already exists\n"
  end
end

vms_config_file = File.expand_path('config/vms.yaml', __dir__)
vms_config      = YAML.load_file(vms_config_file)

Vagrant.configure('2') do |config|

  config.vagrant.plugins = ["vagrant-hosts"]

  vms_config['nodes'].each do |node|
    config.vm.define node['hostname'] do |n|
      n.vm.box      = node['box']
      n.vm.hostname = node['hostname'] + '.' + vms_config['okd']['domain']

      n.vm.network :private_network, ip: node['network']['internal_ip']
      #n.vm.network :public_network, bridge: "enp8s0", :mac => "001122334410"
      #node['network'].each do |net|
      #  n.vm.network :private_network, ip: net['ip']
      #end

      n.vm.provider :virtualbox do |vb|
        vb.memory = node['memory']
        vb.cpus = node['vCPUs']
      end

      # n.vm.provision :hosts do |p|
      #   vms_config['nodes'].each do |entry|
      #     p.add_host entry['networks'][0]['ip'], [entry['hostname'] + '.' + vms_config['okd']['domain']]
      #   end
      # end
      n.vm.provision :shell, path: 'provision/shell/install_common.sh'
      n.vm.provision :shell, path: 'provision/shell/install_' + node['hostname'] + '.sh'
    end
  end
end

