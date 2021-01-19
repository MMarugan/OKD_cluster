#!/bin/bash

echo "Configuring node. Common config..."

# Config steps from https://spiritedengineering.net/2019/08/05/put-red-hat-openshift-on-your-laptop-using-virtualbox-and-openshift-ansible/

# Removes localhost entry for the domain name
sed -i '/127.0.1.1 .*\.okd\.local/d' /etc/hosts

# Installs base packages
yum -y update
yum -y install centos-release-openshift-origin39 wget git net-tools \
    bind-utils yum-utils iptables-services bridge-utils bash-completion \
    kexec-tools sos psacct vim git mlocate

# Creates ssh directory and copies ssh-keys
mkdir -p /root/.ssh
cat /vagrant/cluster_ssh_rsa.key > /root/.ssh/id_rsa
cat /vagrant/cluster_ssh_rsa.key.pub > /root/.ssh/id_rsa.pub
cat /vagrant/cluster_ssh_rsa.key.pub > /root/.ssh/authorized_keys
chmod 600 /root/.ssh/*

# Disables HostKey authentication
cat /etc/ssh/ssh_config  | grep StrictHostKeyChecking | grep -v '^#'
if [ $? -eq 1 ]; then
  echo "   StrictHostKeyChecking no
   UserKnownHostsFile=/dev/null" >> /etc/ssh/ssh_config
fi

# Installs the Extra Packages for Enterprise Linux (EPEL) repository
rpm -q epel-release-7-13 -eq || \
yum -y install \
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo

# Installs docker
yum install -y docker-1.13.1 && systemctl enable --now docker

