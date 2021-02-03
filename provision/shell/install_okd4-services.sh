#!/bin/bash

echo "Configuring services node..."

VAGRANT_FOLDER="/vagrant"
BIND_CONFIG="${VAGRANT_FOLDER}/config/dns/"
HAPROXY_CONFIG="${VAGRANT_FOLDER}/config/haproxy/"
DHCPD_CONFIG="${VAGRANT_FOLDER}/config/dhcpd/"
OKD_CONFIG="${VAGRANT_FOLDER}/config/okd4/"
OKD_VERSION="4.5.0-0.okd-2020-07-29-070316"
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


#######
# DNS #
#######

# Install DNS server
dnf -y install bind bind-utils

# Configure DNS server and zones
cp ${BIND_CONFIG}named.conf /etc/named.conf
cp ${BIND_CONFIG}named.conf.local /etc/named/
mkdir -p /etc/named/zones
cp ${BIND_CONFIG}db.okd.local /etc/named/zones/db.okd.local
cp ${BIND_CONFIG}db.192.168.1 /etc/named/zones/db.192.168.1

# Enable and start the local bind DNS server
systemctl enable named
systemctl start named
systemctl status named

# Enable firewall to receive DNS requests
firewall-cmd --permanent --add-port=53/udp
firewall-cmd --reload

# Point resolver to local bind server
sed -i '/^nameserver.*$/d' /etc/resolv.conf
echo "nameserver 127.0.0.1" >> /etc/resolv.conf
nmcli connection modify "System eth1" ipv4.dns "127.0.0.1"
systemctl restart NetworkManager

# Test
dig +short okd4-services.okd.local.


############
# HA-Proxy #
############

# Insatall ha-proxy
dnf install -y haproxy

# Conpy ha-proxy config
cp ${HAPROXY_CONFIG}haproxy.cfg /etc/haproxy/haproxy.cfg

# Enable and verify ha-proxy
setsebool -P haproxy_connect_any 1
systemctl enable haproxy
systemctl start haproxy
systemctl status haproxy

# Add firewall ports
firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --add-port=22623/tcp
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload


##########
# Apache #
##########

# Install apache httpd server
dnf install -y httpd

# Replaces 80 port by 8080
sed -i -e "s/Listen 80/Listen ${HTTPD_PORT}/" /etc/httpd/conf/httpd.conf

# Enable and start httpd service
setsebool -P httpd_read_user_content 1
systemctl enable httpd
systemctl start httpd

# Adds firewall ports
firewall-cmd --permanent --add-port=${HTTPD_PORT}/tcp
firewall-cmd --reload

# Test
echo "Testing http://okd4-services.okd.local:8080 service..."
curl -s http://okd4-services.okd.local:8080 -o /dev/null

################
## DHCP Server #
################

#dnf install -y dhcp-server
#cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.bk
#cp "${DHCPD_CONFIG}/dhcpd.conf" /etc/dhcp/dhcpd.conf

#systemctl enable dhcpd
#systemctl start dhcpd
#systemctl status dhcpd

#firewall-cmd --add-service=dhcp --permanent
#firewall-cmd --reload

################
## TFTP Server #
################

#dnf -y install tftp-server tftp
#systemctl enable --now tftp.socket
#systemctl enable --now tftp.service
#firewall-cmd --add-service=tftp --permanent
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

# Copy okd config
cd /root
rm -rf install_dir # Needs new config on every execution. Flush folder
mkdir -p install_dir
cp ${OKD_CONFIG}install-config.yaml /root/install_dir

# Set ssh key
PUB_KEY=$(cat .ssh/id_rsa.pub)
sed -i -e '/^sshKey: .*/d' /root/install_dir/install-config.yaml
echo "sshKey: '${PUB_KEY}'" >> /root/install_dir/install-config.yaml

# # Set auth and secret
# AUTH="okdcluster"
# SECRET=$(date +%s | sha256sum | base64 | head -c 64 ; echo)
# sed -i -e "s/pullSecret: '{\"auths\":{\"fake\":{\"auth\": \"bar\"}/pullSecret: '{\"auths\":{\"${AUTH}\":{\"auth\": \"${SECRET}\"}/g" install_dir/install-config.yaml

# Backup config file
cp /root/install_dir/install-config.yaml /root/install_dir/install-config.yaml.bak

# Create manifests
openshift-install create manifests --dir=install_dir/

# Disable master schedulable config
# sed -i -e 's/mastersSchedulable: true/mastersSchedulable: False/' install_dir/manifests/cluster-scheduler-02-config.yml

openshift-install create ignition-configs --dir=install_dir/


############
# Ignition #
############

# Copy config to webserver
rm -rf /var/www/html/okd4 # Flush content on every execution
mkdir -p /var/www/html/okd4
cp -R install_dir/* /var/www/html/okd4/
chown -R apache: /var/www/html/
chmod -R 755 /var/www/html/

# Test
echo "CLUSTER METADATA:"
curl http://okd4-services.okd.local:8080/okd4/metadata.json

# Downloads Fedora CoreOS BareMetal image
cd /var/www/html/okd4/
wget -q https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/${FEDORA_COREOS_VERSION}/x86_64/fedora-coreos-${FEDORA_COREOS_VERSION}-metal.x86_64.raw.xz
wget -q https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/${FEDORA_COREOS_VERSION}/x86_64/fedora-coreos-${FEDORA_COREOS_VERSION}-metal.x86_64.raw.xz.sig
mv fedora-coreos-${FEDORA_COREOS_VERSION}-metal.x86_64.raw.xz fcos.raw.xz
mv fedora-coreos-${FEDORA_COREOS_VERSION}-metal.x86_64.raw.xz.sig fcos.raw.xz.sig
chown -R apache: /var/www/html/
chmod -R 755 /var/www/html/
cd /root/


