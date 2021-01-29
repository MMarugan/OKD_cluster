#!/usr/bin/env bash

uname -r | grep -qe "Microsoft$"
if [ $? -eq 0 ]; then
  VBOXMANAGE="/mnt/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"
  echo "Windows System found"
else
  VBOXMANAGE="VBoxManage"
fi

HOSTS="okd4-bootstrap okd4-control-plane-1 okd4-control-plane-2 okd4-control-plane-3 okd4-compute-1 okd4-compute-2"

for host in $(echo ${HOSTS}); do
  echo ${host}
  "${VBOXMANAGE}" unregistervm "${host}" --delete
done
