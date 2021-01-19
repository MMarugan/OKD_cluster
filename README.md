# OKD_cluster
Deploys OKD cluster using vagrant and virtualbox.  
Installation steps are based on this [Spirited Endineering post](https://spiritedengineering.net/2019/08/05/put-red-hat-openshift-on-your-laptop-using-virtualbox-and-openshift-ansible/)

# Validated with:  
- Debian 10.7  
- Linux 4.19.0-13-amd64  
- Virtual Box 6.1.16-140961~Debian~buster  
- Vagrant 1:2.2.10  

# VMs deployment:

Execute from virtualbox host server:

    host$ vagrant up  

# VMs access:

    host$ vagrant ssh master  
    host$ vagrant ssh infra  
    host$ vagrant ssh compute  

# Cluster configuration (from master node):

Connect to master node:

    host$ vagrant ssh master  

Execute the following commands:

    master$ sudo su -  
    master# ansible all -m ping  

If all the servers respond to ping, proceed with culter creation and configuration:

    master# cd /usr/share/ansible/openshift-ansible/playbooks/  
    master# ansible-playbook prerequisites.yml  
    master# ansible-playbook deploy_cluster.yml  

It takes long time to set up the cluster (around 20 minutes). After this, check the openshift cluster nodes with:

    master# oc get nodes  

The output should be something similar to the following one:

    NAME      STATUS    ROLES     AGE       VERSION  
    compute   Ready     compute   23m       v1.9.1+a0ce1bc657  
    infra     Ready     <none>    23m       v1.9.1+a0ce1bc657  
    master    Ready     master    23m       v1.9.1+a0ce1bc657  

# Webconsole access:

Add to the hosts file the following entry (Update with the corresponding master IP if it has been changed in [config file](/config/vms.yaml) file for master node):

    192.168.50.11 master  

And access to the web console using the following URL:

[https://master:8443/](https://master:8443/)

(NOTE) A self-signed certificate warning may appears in the browser and it has to be accepted.


