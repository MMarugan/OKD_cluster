#!/usr/bin/env bash

# Config from repo
cd ../../

git clone https://github.com/cragr/okd4_files.git

cp okd4_files/db.* okd4_files/named.conf* OKD_cluster/config/dns/
cp okd4_files/haproxy.cfg OKD_cluster/config/haproxy
cp okd4_files/install-config.yaml OKD_cluster/config/okd4

cd -
