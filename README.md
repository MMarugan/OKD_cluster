# OKD 4 cluster
Deploys OKD cluster using vagrant and virtualbox.  
Installation steps are based on [this](https://www.openshift.com/blog/guide-to-installing-an-okd-4-4-cluster-on-your-home-lab) and [this guide](https://itnext.io/guide-installing-an-okd-4-5-cluster-508a2631cbee?gi=bd1f22cb39a9)  
Also some useful code in github [OKD repo](https://github.com/openshift/okd)

# VMs deployment
## Linux:
### Validated with the following software versions:  
- Debian 10.7  
- Linux 4.19.0-13-amd64  
- Virtual Box 6.1.16-140961\~Debian\~buster  
- Vagrant 1:2.2.10  

Execute from virtualbox host server:
````
host:repo_path$ vagrant up
````

## Windows:
````
repo_path> vagrant.exe up
````
### Validated with the following software versions:
  - Vagrant [2.2.5](https://releases.hashicorp.com/vagrant/2.2.5/)  
  - VirtualBox [6.0.4r128413](https://download.virtualbox.org/virtualbox/6.0.4/VirtualBox-6.0.4-128413-Win.exe)  
  - VirtualBox [6.0.4r128413 Extension Pack](https://download.virtualbox.org/virtualbox/6.0.6/Oracle_VM_VirtualBox_Extension_Pack-6.0.6.vbox-extpack)  
  
NOTE: Some rsync problems have been detected with different Vagrant version than ````2.2.5````.  


It takes long time to set up the cluster (around 20 minutes). After this, it's possible to check the openshift cluster nodes with:

## Webconsole access:
Add to the hosts file the following entry (Update it with the corresponding one if it has been changed in [config file](/config/vms.yaml) file for master node)
````
192.168.50.11 master.okd.local
````
to access to the web console using the following URL:

[https://master.okd.local:8443/](https://master.okd.local:8443/)

- (NOTE I) A self-signed certificate warning may appears in the browser and it has to be accepted.  
- (NOTE II) Default credentials provisioned in these deployment scripts are ````admin / okdadmin123````)  

# Troubleshooting:
- ## VMs access:
````
host$ vagrant ssh master
host$ vagrant ssh infra
host$ vagrant ssh compute
````
- ## Ansible connectivity tests (from master):
````
master$ sudo su -
master# ansible all -m ping
````
- ## Manual ansible openshift deployment execution (from master):
````
master# cd /usr/share/ansible/openshift-ansible/playbooks/
master# ansible-playbook prerequisites.yml
master# ansible-playbook deploy_cluster.yml
````
- ## Check openshift nodes (from master)  

````
master# oc get nodes

NAME      STATUS    ROLES     AGE       VERSION  
compute   Ready     compute   23m       v1.9.1+a0ce1bc657  
infra     Ready     <none>    23m       v1.9.1+a0ce1bc657  
master    Ready     master    23m       v1.9.1+a0ce1bc657  
````

