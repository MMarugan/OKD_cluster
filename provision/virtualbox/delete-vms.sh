#!/usr/bin/env bash

HOSTS="okd4-bootstrap okd4-control-plane-1 okd4-control-plane-2 okd4-control-plane-3 okd4-compute-1 okd4-compute-2"

for host in $(echo ${HOSTS}); do
  echo ${host}
  VBoxManage unregistervm "${host}" --delete
done
