#!/bin/bash

echo "Configuring master node..."

# Installs ansible 2.4.3.0
ANSIBLE_VERSION="2.4.3.0"
yum -y --enablerepo=epel install pyOpenSSL
rpm -q ansible -eq || \
yum -y install \
    https://cbs.centos.org/kojifiles/packages/ansible/${ANSIBLE_VERSION}/1.el7/noarch/ansible-${ANSIBLE_VERSION}-1.el7.noarch.rpm
rpm -q ansible-doc -eq || \
yum -y install \
    https://cbs.centos.org/kojifiles/packages/ansible/${ANSIBLE_VERSION}/1.el7/noarch/ansible-doc-${ANSIBLE_VERSION}-1.el7.noarch.rpm

# Installs ansible openshift playbooks
yum install -y openshift-ansible
[[ ! -f /etc/ansible/hosts.bk ]] && mv /etc/ansible/hosts /etc/ansible/hosts.bk
cat /vagrant/config/ansible-hosts > /etc/ansible/hosts

# # dnsmasq installation and configuration (IP resolution included in /etc/hosts)
# yum install -y dnsmasq #dnsmasq-utils
# [[ ! -f /etc/dnsmasq.conf.bk ]] && mv /etc/dnsmasq.conf /etc/dnsmasq.conf.bk
# cat /vagrant/config/dnsmasq.conf> /etc/dnsmasq.conf
# systemctl restart dnsmasq.service
# echo "# Local dnsmasq configuration" > /etc/resolv.conf
# echo "nameserver 127.0.0.1" >> /etc/resolv.conf

# Test ansible connectivity
ansible all -m ping

# Execute ansible to configure and deploy openshift
cd /usr/share/ansible/openshift-ansible/playbooks/
ansible-playbook prerequisites.yml && \
ansible-playbook deploy_cluster.yml

# Set a password for admin user
mkdir -p "/etc/origin/master"
echo "okdadmin123" | htpasswd -i -c  "/etc/origin/master/htpasswd" admin

# Check openshift nodes
oc get nodes

