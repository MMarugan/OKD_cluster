# OKD_cluster
Deploys OKD cluster using vagrant and virtualbox.  
Installation steps are based on this [Spirited Endineering post](https://spiritedengineering.net/2019/08/05/put-red-hat-openshift-on-your-laptop-using-virtualbox-and-openshift-ansible/)

# Validated with:  
- Debian 10.7  
- Linux 4.19.0-13-amd64  
- Virtual Box 6.1.16-140961~Debian~buster  
- Vagrant 1:2.2.10  

# Execution:

    $ vagrant up
    
# VMs access:

    $ vagrant ssh master
    $ vagrant ssh infra
    $ vagrant ssh compute

