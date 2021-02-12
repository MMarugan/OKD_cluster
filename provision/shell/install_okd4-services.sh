#!/bin/bash

echo "Configuring services node..."

VAGRANT_FOLDER="/vagrant"
BIND_CONFIG="${VAGRANT_FOLDER}/config/dns/"
HAPROXY_CONFIG="${VAGRANT_FOLDER}/config/haproxy/"
DHCPD_CONFIG="${VAGRANT_FOLDER}/config/dhcpd/"
OKD_CONFIG="${VAGRANT_FOLDER}/config/okd4/"
OKD_VERSION="4.5.0-0.okd-2020-10-15-235428"
# OKD_VERSION="4.4.0-0.okd-2020-05-23-055148-beta5"

HTTPD_PORT="8080"

FEDORA_COREOS_VERSION="32.20200715.3.0"

pathmunge () {
        if ! echo $PATH | /bin/egrep -q "(^|:)$1($|:)" ; then
           if [ "$2" = "after" ] ; then
              PATH=$PATH:$1
           else
              PATH=$1:$PATH
           fi
        fi
}

############
# Firewall #
############

# Install firewall
dnf -y install firewalld

# Enable and start the firewall
systemctl enable firewalld
systemctl start firewalld
systemctl status firewalld

# Enable IP forwarding
sysctl -w net.ipv4.ip_forward=1
# Make it persistent
sed -i -e '/^net\.ipv4\.ip_forward:/d'
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
# Create zones and masquerade settings
firewall-cmd --zone=external --add-interface=eth0 --permanent
firewall-cmd --zone=internal --add-interface=eth1 --permanent
firewall-cmd --zone=external --add-masquerade --permanent
firewall-cmd --permanent --direct --passthrough ipv4 -t nat -I POSTROUTING -o eth0 -j MASQUERADE -s 192.168.61.0/24
firewall-cmd --complete-reload

#######
# DNS #
#######

# Install DNS server
echo "------ Installing and configuring DNS saerver (bind)..."
dnf -y install bind bind-utils

# Configure DNS server and zones
cp ${BIND_CONFIG}named.conf /etc/named.conf
cp ${BIND_CONFIG}named.conf.local /etc/named/
mkdir -p /etc/named/zones
cp ${BIND_CONFIG}db.okd.local /etc/named/zones/db.okd.local
cp ${BIND_CONFIG}db.192.168.1 /etc/named/zones/db.192.168.61
sed -i "s~192\.168\.1~192\.168\.61~g" /etc/named.conf /etc/named/named.conf* /etc/named/zones/db*
sed -i "s~1.168.192.in-addr.arpa~61.168.192.in-addr.arpa~g" /etc/named.conf /etc/named/named.conf* /etc/named/zones/db*

# Enable and start the local bind DNS server
systemctl enable named
systemctl start named
systemctl status named

# Enable firewall to receive DNS requests
firewall-cmd --permanent --zone=internal --add-port=53/udp
firewall-cmd --reload

# Point resolver to local bind server
echo 'search okd.local
nameserver 192.168.61.210' > /etc/resolv.conf
# nmcli connection modify "System eth1" ipv4.dns "127.0.0.1"
# systemctl restart NetworkManager

# Test
echo "------ Ip of okd4-services.okd.local:"
dig +short okd4-services.okd.local.
echo "------ lab.okd.local resolution:"
dig lab.okd.local
echo "------ Reverse resolution to 192.168.61.210"
dig -x 192.168.61.210
echo "------ DNS done ------"


############
# HA-Proxy #
############

# Insatall ha-proxy
echo "------ Installing and configuring load balacer (ha-proxy)..."
dnf install -y haproxy

# Conpy ha-proxy config
cp ${HAPROXY_CONFIG}haproxy.cfg /etc/haproxy/haproxy.cfg
sed -i "s~192\.168\.1~192\.168\.61~g" /etc/haproxy/haproxy.cfg

# Enable and verify ha-proxy
setsebool -P haproxy_connect_any 1
systemctl enable haproxy
systemctl start haproxy
systemctl status haproxy

# Add firewall ports
firewall-cmd --permanent --zone=internal --add-port=6443/tcp
firewall-cmd --permanent --zone=internal --add-port=22623/tcp
firewall-cmd --permanent --zone=internal --add-port=9000/tcp # haproxy web interface
firewall-cmd --permanent --zone=internal --add-service=http
firewall-cmd --permanent --zone=internal --add-service=https
firewall-cmd --reload


##########
# Apache #
##########

# Install apache httpd server
echo "------ Installing httpd server..."
dnf install -y httpd

# Replaces 80 port by 8080
sed -i -e "s/Listen 80/Listen ${HTTPD_PORT}/" /etc/httpd/conf/httpd.conf

# Enable and start httpd service
setsebool -P httpd_read_user_content 1
systemctl enable httpd
systemctl start httpd

# Adds firewall ports
firewall-cmd --permanent --zone=internal --add-port=${HTTPD_PORT}/tcp
firewall-cmd --reload

# Test
echo "------ Testing http://okd4-services.okd.local:8080 service..."
curl -s http://okd4-services.okd.local:8080 -o /dev/null

###############
# DHCP Server #
###############

dnf install -y dhcp-server
cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.bk
cp "${DHCPD_CONFIG}/dhcpd.conf" /etc/dhcp/dhcpd.conf
sed -i 's#192.168.1.#192.168.61.#g' /etc/dhcp/dhcpd.conf

systemctl enable dhcpd
systemctl start dhcpd
systemctl status dhcpd

firewall-cmd --zone=internal --add-service=dhcp --permanent
firewall-cmd --reload

################
## TFTP Server #
################

#dnf -y install tftp-server tftp
#systemctl enable --now tftp.socket
#systemctl enable --now tftp.service
#firewall-cmd --zone=internal --add-service=tftp --permanent
#firewall-cmd --reload

##############
# PXE Config #
##############

# dnf install -y syslinux
# TFTP_ROOT_FOLDER="/var/lib/tftpboot/"
# SYSLINUX_SRC_FOLDER="/usr/share/syslinux/"
# PXE_FILES="pxelinux.0 menu.c32 ldlinux.c32 libutil.c32"
# for pxe_file in $(echo "${PXE_FILES}"); do
#   cp "${SYSLINUX_SRC_FOLDER}${pxe_file}" "${TFTP_ROOT_FOLDER}"
# done

# mkdir /var/lib/tftpboot/pxelinux.cfg
# cp -f /vagrant/config/pxe/default /var/lib/tftpboot/pxelinux.cfg/

# ------------------------------------------------------------------
# OLD
# mkdir /var/lib/tftpboot/iso
# wget https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/32.20200715.3.0/x86_64/fedora-coreos-32.20200715.3.0-live.x86_64.iso
# mv fedora-coreos-32.20200715.3.0-live.x86_64.iso /var/lib/tftpboot/iso
# mount -o ro,loop /var/lib/tftpboot/iso/fedora-coreos-32.20200715.3.0-live.x86_64.iso /mnt
# cp -rf /mnt/isolinux /var/lib/tftpboot/
# cp -rf /mnt/images /var/lib/tftpboot/

# dnf install -y podman
# podman run --privileged --pull=always --rm -v .:/data -w /data quay.io/coreos/coreos-installer:release download -f pxe
# ------------------------------------------------------------------

####################
# OpenShift Config #
####################

# Install wget package
echo "------ Getting openshift client and installer..."
dnf install -y wget
# Get OKD software
mkdir -p /root/oc-temp/
cd /root/oc-temp/
wget -q https://github.com/openshift/okd/releases/download/${OKD_VERSION}/openshift-client-linux-${OKD_VERSION}.tar.gz
wget -q https://github.com/openshift/okd/releases/download/${OKD_VERSION}/openshift-install-linux-${OKD_VERSION}.tar.gz
tar -zxf openshift-client-linux-${OKD_VERSION}.tar.gz
tar -zxf openshift-install-linux-${OKD_VERSION}.tar.gz
mv kubectl oc openshift-install /usr/local/bin/
cd ..
rm -rf /root/oc-temp/
pathmunge "/usr/local/bin/"
oc version
openshift-install version
LINE="source <(oc completion bash)"
grep -qsF "${LINE}" /root/.bashrc || echo "${LINE}" >> /root/.bashrc # oc completion in bash
source <(oc completion zsh)

# Copy okd config
echo "------ Creating installation configuration..."
cd /root
rm -rf install_dir # Needs new config on every execution. Flush folder
mkdir -p install_dir
cp ${OKD_CONFIG}install-config.yaml /root/install_dir

# Set ssh key
PUB_KEY=$(cat .ssh/id_rsa.pub)
sed -i -e '/^sshKey: .*/d' /root/install_dir/install-config.yaml
echo "sshKey: '${PUB_KEY}'" >> /root/install_dir/install-config.yaml

# # Set auth and secret
# PULLSECRETS='{"auths":{"cloud.openshift.com":{"auth":...' # Get it from https://cloud.redhat.com/openshift/install/metal/user-provisioned
# sed -i -e "s/pullSecret: '{\"auths\":{\"fake\":{\"auth\": \"bar\"}/pullSecret: ${PULLSECRETS}/g" install_dir/install-config.yaml

# Backup config file
cp /root/install_dir/install-config.yaml /root/install_dir/install-config.yaml.bak

# Create manifests
echo "------ Creating intallation manifests..."
openshift-install create manifests --dir=install_dir/
# Disable master schedulable config (it avoids to set the worker role to master nodes)
sed -i -e 's/mastersSchedulable: true/mastersSchedulable: False/' install_dir/manifests/cluster-scheduler-02-config.yml
openshift-install create ignition-configs --dir=install_dir/

echo "------ Setting credentials for openshift client (oc)"
mkdir -p /root/.kube/
cp install_dir/auth/kubeconfig /root/.kube/config

echo '#!/usr/bin/env bash
openshift-install --dir=install_dir wait-for bootstrap-complete --log-level=info' > check-deployment.sh
chmod +x check-deployment.sh

echo '#!/usr/bin/env bash
watch -n 5 "oc get clusterversion; echo ------; oc get clusteroperators"' > check-progress.sh
chmod +x check-progress.sh



############
# Ignition #
############

# Copy config to webserver
echo "------ Copying ignition config to httpd..."
rm -rf /var/www/html/okd4 # Flush content on every execution
mkdir -p /var/www/html/okd4
cp -R install_dir/* /var/www/html/okd4/
chown -R apache: /var/www/html/
chmod -R 755 /var/www/html/

# Test
echo "CLUSTER METADATA:"
curl http://okd4-services.okd.local:8080/okd4/metadata.json

# Downloads Fedora CoreOS BareMetal image
echo "------ Downloading Fedora CoreOS BareMetal images..."
cd /var/www/html/okd4/
wget -q https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/${FEDORA_COREOS_VERSION}/x86_64/fedora-coreos-${FEDORA_COREOS_VERSION}-metal.x86_64.raw.xz
wget -q https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/${FEDORA_COREOS_VERSION}/x86_64/fedora-coreos-${FEDORA_COREOS_VERSION}-metal.x86_64.raw.xz.sig
mv fedora-coreos-${FEDORA_COREOS_VERSION}-metal.x86_64.raw.xz fcos.raw.xz
mv fedora-coreos-${FEDORA_COREOS_VERSION}-metal.x86_64.raw.xz.sig fcos.raw.xz.sig
chown -R apache: /var/www/html/
chmod -R 755 /var/www/html/
cd /root/
echo "------ Done ------"

