#!/bin/bash

echo "Configuring node. Common config..."

# Config steps from https://spiritedengineering.net/2019/08/05/put-red-hat-openshift-on-your-laptop-using-virtualbox-and-openshift-ansible/

yum -y update

yum -y install centos-release-openshift-origin39 wget git net-tools \
    bind-utils yum-utils iptables-services bridge-utils bash-completion \
    kexec-tools sos psacct vim git mlocate

# Generates ssh key
mkdir -p /root/.ssh
ssh-keygen -t rsa \
    -f /root/.ssh/id_rsa -N ''

# Install the Extra Packages for Enterprise Linux (EPEL) repository
rpm -q epel-release-7-13 -eq || \
yum -y install \
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo

# Install ansible 2.4.3.0
ANSIBLE_VERSION="2.4.3.0"
yum -y --enablerepo=epel install pyOpenSSL
rpm -q ansible -eq || \
yum -y install \
    https://cbs.centos.org/kojifiles/packages/ansible/${ANSIBLE_VERSION}/1.el7/noarch/ansible-${ANSIBLE_VERSION}-1.el7.noarch.rpm
rpm -q ansible-doc -eq || \
yum -y install \
    https://cbs.centos.org/kojifiles/packages/ansible/${ANSIBLE_VERSION}/1.el7/noarch/ansible-doc-${ANSIBLE_VERSION}-1.el7.noarch.rpm

yum install -y docker-1.13.1 && systemctl enable --now docker

