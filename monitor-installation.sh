#!/usr/bin/env bash
openshift-install --dir=install_dir/ wait-for bootstrap-complete --log-level=info
