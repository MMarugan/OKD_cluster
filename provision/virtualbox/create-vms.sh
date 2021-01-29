#!/bin/bash

ISO_BASE_PATH="/home/manu/Downloads/"

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

for host in "${!HOSTS[@]}"; do
  ISO="${ISO_BASE_PATH}${HOSTS[$host]}"
  MAC="${MACS[$host]}"

  echo "------ ${host} - ${ISO} ------"

  VBoxManage createvm --name "${host}" --ostype Fedora_64 --register
  # ---
  VBoxManage modifyvm "${host}" --memory 4096 --cpus 1
  VBoxManage modifyvm "${host}" --vram 16 --graphicscontroller vmsvga
  VBoxManage modifyvm "${host}" --audio none
  # ---
  NETNAME=$(VBoxManage list -l hostonlyifs | grep 192.168.61.1 -B 3 | grep Name | awk '{print $2}')
  VBoxManage modifyvm "${host}" --nic1 hostonly --hostonlyadapter1 "${NETNAME}" --nictype1 Am79C970A --macaddress1 "${MAC}"
  # ---
  VBoxManage createmedium disk --filename "${host}"/disk0.vdi --size 8192 --variant Standard
  DISKUUID=$(VBoxManage list hdds | grep "\/${host}\/disk0.vdi" -B 4 | grep "^UUID:" | awk '{print $2}')
  vboxmanage storagectl "${host}" --name "SATA" --add sata --controller IntelAHCI --portcount 1 --bootable on
  VBoxManage storageattach "${host}" \
                           --storagectl "SATA" \
                           --device 0 \
                           --port 0 \
                           --type hdd \
                           --medium "${host}"/disk0.vdi
  # ---
  VBoxManage storagectl "${host}" --name "IDE" --add ide
  VBoxManage storageattach "${host}" --storagectl "IDE" --port 0  --device 0 --type dvddrive --medium "${ISO}"
  # ---
  VBoxManage modifyvm "${host}" --boot1 disk --boot2 dvd --boot3 floppy
done
