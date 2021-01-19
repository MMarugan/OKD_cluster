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

# Generates ssh key
mkdir -p /root/.ssh
ssh-keygen -t rsa \
    -f /root/.ssh/id_rsa -N ''

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

# Installs ansible 2.4.3.0
ANSIBLE_VERSION="2.4.3.0"
yum -y --enablerepo=epel install pyOpenSSL
rpm -q ansible -eq || \
yum -y install \
    https://cbs.centos.org/kojifiles/packages/ansible/${ANSIBLE_VERSION}/1.el7/noarch/ansible-${ANSIBLE_VERSION}-1.el7.noarch.rpm
rpm -q ansible-doc -eq || \
yum -y install \
    https://cbs.centos.org/kojifiles/packages/ansible/${ANSIBLE_VERSION}/1.el7/noarch/ansible-doc-${ANSIBLE_VERSION}-1.el7.noarch.rpm

# Installs docker
yum install -y docker-1.13.1 && systemctl enable --now docker

# Installs ansible
yum install -y openshift-ansible
[[ ! -f /etc/ansible/hosts.bk ]] && mv /etc/ansible/hosts /etc/ansible/hosts.bk
cat /vagrant/config/ansible-hosts > /etc/ansible/hosts

# Set a root password for http
mkdir -p /etc/origin/master
echo "okdroot123" | htpasswd -i -c  /etc/origin/master/htpasswd root

# Set a password for admin user
echo "okdadmin123" | htpasswd -i -c  /etc/origin/master/htpasswd admin

# # dnsmasq installation and configuration
# yum install -y dnsmasq #dnsmasq-utils
# [[ ! -f /etc/dnsmasq.conf.bk ]] && mv /etc/dnsmasq.conf /etc/dnsmasq.conf.bk
# cat /vagrant/config/dnsmasq.conf> /etc/dnsmasq.conf
# systemctl restart dnsmasq.service
# echo "# Local dnsmasq configuration" > /etc/resolv.conf
# echo "nameserver 127.0.0.1" >> /etc/resolv.conf

