#!/bin/bash

uname -r | grep -qe "Microsoft$"
if [ $? -eq 0 ]; then
  echo "Windows System found"
  VBOXMANAGE="/mnt/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"
  ISO_BASE_PATH="D:/OKD/ISO/"
  VM_BASE_PATH="D:/OKD/VMs/"
else
  VBOXMANAGE="VBoxManage"
  ISO_BASE_PATH="~/Downloads/"
fi

PFSENSE_HOST="okd4-pfsense"
PFSENSE_ISO="${ISO_BASE_PATH}pfSense-CE-2.4.5-RELEASE-p1-amd64.iso"
PFSENSE_MAC="001122334499"


declare -A HOSTS=(
  ["okd4-bootstrap"]="fedora-coreos-32.20200715.3.0-live.x86_64-bootstrap.iso"
  ["okd4-control-plane-1"]="fedora-coreos-32.20200715.3.0-live.x86_64-controlplane.iso"
  ["okd4-control-plane-2"]="fedora-coreos-32.20200715.3.0-live.x86_64-controlplane.iso"
  ["okd4-control-plane-3"]="fedora-coreos-32.20200715.3.0-live.x86_64-controlplane.iso"
  ["okd4-compute-1"]="fedora-coreos-32.20200715.3.0-live.x86_64-worker.iso"
  ["okd4-compute-2"]="fedora-coreos-32.20200715.3.0-live.x86_64-worker.iso"
)

declare -A MACS=(
  ["okd4-bootstrap"]="001122334400"
  ["okd4-control-plane-1"]="001122334401"
  ["okd4-control-plane-2"]="001122334402"
  ["okd4-control-plane-3"]="001122334403"
  ["okd4-compute-1"]="001122334404"
  ["okd4-compute-2"]="001122334405"
)

# # Create pfsense host
#   host="${PFSENSE_HOST}"
#   "${VBOXMANAGE}" createvm --name "${host}" --ostype Fedora_64 --register
#   # ---
#   "${VBOXMANAGE}" modifyvm "${host}" --memory 1024  --cpus 1 --longmode on --apic on
#   "${VBOXMANAGE}" modifyvm "${host}" --vram 16 --graphicscontroller vmsvga
#   "${VBOXMANAGE}" modifyvm "${host}" --audio none
#   # ---
#   NETNAME=$("${VBOXMANAGE}" list -l hostonlyifs | grep 192.168.1.1 -B 3 | grep Name | awk '{print $2}')
#   "${VBOXMANAGE}" modifyvm "${host}" --nic1 hostonly --hostonlyadapter1 "${NETNAME}" --nictype1 Am79C970A --macaddress1 "${PFSENSE_MAC}"
#   "${VBOXMANAGE}" modifyvm "${host}" --nic2 nat --nictype2 Am79C970A
#   # ---
#   "${VBOXMANAGE}" createmedium disk --filename "${VM_BASE_PATH}${host}-disk0.vdi" --size 8192 --variant Standard
#   DISKUUID=$("${VBOXMANAGE}" list hdds | grep "${host}-disk0.vdi" -B 4 | grep "^UUID:" | awk '{print $2}')
#   "${VBOXMANAGE}" storagectl "${host}" --name "SATA" --add sata --controller IntelAHCI --portcount 1 --bootable on
#   "${VBOXMANAGE}" storageattach "${host}" \
#                            --storagectl "SATA" \
#                            --device 0 \
#                            --port 0 \
#                            --type hdd \
#                            --medium "${VM_BASE_PATH}${host}-disk0.vdi"
#   # ---
#   "${VBOXMANAGE}" storagectl "${host}" --name "IDE" --add ide
#   "${VBOXMANAGE}" storageattach "${host}" --storagectl "IDE" --port 0  --device 0 --type dvddrive --medium "${PFSENSE_ISO}"
#   # ---
#   "${VBOXMANAGE}" modifyvm "${host}" --boot1 disk --boot2 dvd --boot3 floppy


# Create fedora hosts
for host in "${!HOSTS[@]}"; do
  ISO="${ISO_BASE_PATH}${HOSTS[$host]}"
  MAC="${MACS[$host]}"

  echo "------ ${host} - ${ISO} ------"

  "${VBOXMANAGE}" createvm --name "${host}" --ostype Fedora_64 --register
  # ---
  "${VBOXMANAGE}" modifyvm "${host}" --memory 4096 --cpus 2 --longmode on --apic on
  "${VBOXMANAGE}" modifyvm "${host}" --vram 16 --graphicscontroller vmsvga
  "${VBOXMANAGE}" modifyvm "${host}" --audio none
  # ---
  NETNAME=$("${VBOXMANAGE}" list -l hostonlyifs | grep 192.168.1.1 -B 3 | grep Name | awk '{print $2}')
  "${VBOXMANAGE}" modifyvm "${host}" --nic1 hostonly --hostonlyadapter1 "${NETNAME}" --nictype1 Am79C970A --macaddress1 "${MAC}"
  # ---
  "${VBOXMANAGE}" createmedium disk --filename "${VM_BASE_PATH}${host}-disk0.vdi" --size 8192 --variant Standard
  DISKUUID=$("${VBOXMANAGE}" list hdds | grep "${host}-disk0.vdi" -B 4 | grep "^UUID:" | awk '{print $2}')
  "${VBOXMANAGE}" storagectl "${host}" --name "SATA" --add sata --controller IntelAHCI --portcount 1 --bootable on
  "${VBOXMANAGE}" storageattach "${host}" \
                           --storagectl "SATA" \
                           --device 0 \
                           --port 0 \
                           --type hdd \
                           --medium "${VM_BASE_PATH}${host}-disk0.vdi"
  # ---
  "${VBOXMANAGE}" storagectl "${host}" --name "IDE" --add ide
  "${VBOXMANAGE}" storageattach "${host}" --storagectl "IDE" --port 0  --device 0 --type dvddrive --medium "${ISO}"
  # ---
  "${VBOXMANAGE}" modifyvm "${host}" --boot1 disk --boot2 dvd --boot3 floppy
done

