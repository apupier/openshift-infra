# Instructions to install OpenShift and Cloud Native Features

This project details how to provision OpenShift Origin using different tools / bootstrapping methods such as: a pre-built ISO image, native hypervisor, or Cloud provider as presented below:

| Tool       | Run As               | ISO                    |  Hypervisor  | Cloud Provider |
| ---------- | -------------------- | -----------------------| :----------: | -------------- |
| MiniShift  | `oc cluster up`      | CentOS or boot2docker  | Xhyve        | Local Machine  |
| Ansible    | `oc cluster up`      | Centos 7               | Virtualbox   | Local Machine  |
| Ansible    | `systemctl service`  | Centos 7               | -            | Hetzner        |


Independent of the approach you choose, you'll be able to install or configure OpenShift
to play with the Hands On Lab, run local demos, or simply test one of the following features of the OpenShift system:

- Create list of users/passwords and their corresponding projects
- Grant Cluster admin role to an OpenShift user 
- Set the Master-configuration of Openshift to use `htpasswd` as its identity provider
- Enable Persistence using `hotPath` as `persistenceVolume`
- Install Nexus Repository Server
- Install Jenkins and configure it to handle `s2i` builds started within the OpenShift project
- Install Distributed Tracing - Jaeger
- Install ServiceMesh - Istio
- Deploy the [Ansible Service Broker](http://automationbroker.io/)
- Install and enable the Fabric8 [Launcher](http://fabric8-launcher)

**NOTE**: Due to some limitations we are currently facing with `minishift|cdk`, where
we can't use Ansible Playbooks to provision our different features once OpenShift is installed, we will instead use 
bash script, manual `oc` commands or `Minishift` addons to install some of the features.  

Table of Contents
=================

   * [Installation of Openshift](#installation-of-openshift)
      * [Minishift](#minishift)
      * [Virtualbox](#virtualbox)
         * [MacOS's users only](#macoss-users-only)
         * [Common steps](#common-steps)
         * [Create CentOS vm on Virtualbox](#create-centos-vm-on-virtualbox)
      * [Using Cloud Provider - Hetzner](#using-cloud-provider---hetzner)
   * [Turn on your OpenShift machine into a cloud Native Dev environment](#turn-on-your-openshift-machine-into-a-cloud-native-dev-environment)

# Installation of Openshift

## Minishift

This section explains how to provision OpenShift Origin 3.9.0 using `MiniShift`, a bare metal CentOS vm running a Docker daemon or with the help of a cloud provider - (In this case, [Hetzner](https://www.hetzner.com/)), and the following additional projects:

- Fabric8 Launcher
- Ansible Service Broker
 
First, use the following bash script `bootstrap_vm.sh <image_cache_boolean> <ocp_version>`, which will create a `centos7` vm using the `xhyve` hypervisor.

Here is a summary of what the script will do:

- Create a MiniShift `demo` profile
- Git clone `MiniShift addons` repo to install the `ansible-service-broker`
- Enable/disable `MiniShift` cache (according to the `boolean` parameter)
- Install the docker images within the OpenShift registry, according to the ocp version defined
- Start `MiniShift` using the experimental features

```bash
cd minishift    
./bootstrap_vm.sh true 3.9.0
```

**NOTE** : The caching option can be used in order to export the docker images locally, which will speed up the bootstrap process next time you recreate the OpenShift virtual machine / installation.

**NOTE** : The user to use to access the OpenShift installation is `admin` with the password `admin`. This user has been granted the OpenShift Cluster Admin role.

**NOTE** : Once the virtual machine has been created, it can be stopped/started using the commands `minishift stop|start --profile demo`.

## Virtualbox

This section explains how you can create a customized CentOS Generic Cloud `qcow2` image and repackage it as a `vmdk` file for Virtualbox.

### MacOS's users only

As MacOS users can't execute natively all the linux commands, part of the different bash scripts, it is required to create a Linux vm on virtualbox:

- Create and start a vm on virtualbox
```bash
cd virtualbox/build-centos-iso
vagrant plugin install vagrant-vbguest
vagrant plugin install sshd
vagrant up
vagrant ssh
```

- Move to the `install` directory mounted into the vm by vagrant
```bash
cd install 
```

### Common steps

In order to prepare the Centos VM for the cloud, we are using the [cloud-init](http://cloudinit.readthedocs.io/en/latest) tool which is a set of python scripts and utilities to make your cloud images be all they can be! 

We will use this tool to install our Cloud on Virtualbox, with your own parameters such as:

- Network configuration (NAT, vboxnet),
- User : `root`, pwd : `centos`
- Additionally add non root user, user, password, ssh authorized key, 
- yum packages, ...


**Note** : Centos 7 ISO packages include version `0.7.9` of the `cloud-init` tool by default. 

To prepare your CentOS image (the `iso` file that Virtualbox will use to bootstrap your vm), you will have to execute the following script, which will perform the following tasks :

- Add your SSH public key within the `user-data` file using as input the `user-data.tpl` file 
- Package the files `user-data` and `meta-data` within an ISO file created using `genisoimage` application
- Download the CentOS Generic Cloud image and save it under `/LOCAL/HOME/DIR/images`
- Convert the `qcow2` Centos ISO image to `vmdk` file format
- Save the vmdk image under `/LOCAL/HOME/DIR/images`

Execute this bash script to repackage the CentOS ISO image and pass your parameters for `</LOCAL/HOME/DIR>` and the name of the Generic Cloud Centos file `<QCOW2_IMAGE_NAME>`, which the script downloads from `http://cloud.centos.org/centos/7/images/`

```bash
cd virtualbox/build-centos-iso/cloud-init
./new-iso.sh </LOCAL/HOME/DIR> <QCOW2_IMAGE_NAME> <BOOLEAN_RESIZE_QCOQ_IMAGE>
```

Example:
```bash
./new-iso.sh /Users/dabou CentOS-7-x86_64-GenericCloud.qcow2c true
##### 1. Add ssh public key and create user-data file
##### 2. Generating ISO file containing user-data, meta-data files and used by cloud-init at bootstrap
Total translation table size: 0
Total rockridge attributes bytes: 331
Total directory bytes: 0
Path table size(bytes): 10
Max brk space used 0
183 extents written (0 MB)
#### 3. Downloading  http://cloud.centos.org/centos/7/images//CentOS-7-x86_64-GenericCloud.qcow2c ....
--2018-03-15 08:55:14--  http://cloud.centos.org/centos/7/images//CentOS-7-x86_64-GenericCloud.qcow2c
Resolving cloud.centos.org (cloud.centos.org)... 162.252.80.138
Connecting to cloud.centos.org (cloud.centos.org)|162.252.80.138|:80... connected.
HTTP request sent, awaiting response... 200 OK
Length: 394918400 (377M)
Saving to: '/Users/dabou/images/CentOS-7-x86_64-GenericCloud.qcow2c'

100%[==========================================================================================================================================================================================================>] 394,918,400 1.15MB/s   in 3m 54s 

2018-03-15 08:59:08 (1.61 MB/s) - '/Users/dabou/images/CentOS-7-x86_64-GenericCloud.qcow2c' saved [394918400/394918400]

#### Optional - Resizing qcow2 Image - +20G
Image resized.
#### 4. Converting QCOW to VMDK format
    (100.00/100%)
Done
```
The new ISO image is created locally on your machine under the directory `$HOME/images`
```bash
ls -la $HOME/images
-rw-r--r--@   1 dabou  staff         6148 Mar 15 09:06 .DS_Store
-rw-r--r--    1 dabou  staff     61675897 Mar 15 09:06 CentOS-7-x86_64-GenericCloud.qcow2c
-rw-r--r--    1 dabou  staff            0 Mar 15 09:06 centos7.vmdk
-rw-r--r--    1 dabou  staff       374784 Mar 15 09:06 vbox-config.iso
```

### Create CentOS vm on VirtualBox

To automatically create a new Virtualbox VM using the customized CentOS ISO image (the `iso` file including the `cloud-init` config files), execute the following script `create_vm.sh` on the machine running VirtualBox. This script will perform the following tasks:

- Power off the virtual machine if it is running
- Unregister the vm `$VIRTUAL_BOX_NAME` and delete it
- Rename Centos `vmdk` to `disk.vmdk`
- Create `vboxnet0` network and set dhcp server IP : `192.168.99.50/24`
- Create Virtual Machine
- Define NIC adapters; NAT accessing internet and `vboxnet0` to create a private network between the host and the guest
- Customize vm; ram, cpu, ...
- Create IDE Controller, attach iso dvd and vmdk disk
- Start vm and configure SSH Port forward

```bash
cd virtualbox/build-centos-iso/cloud-init 
./create-vm.sh </LOCAL/HOME/DIR>
```
Example:
```bash
./create-vm.sh /Users/dabou
######### Poweroff machine if it runs
VBoxManage: error: Could not find a registered machine named 'CentOS-7'
VBoxManage: error: Details: code VBOX_E_OBJECT_NOT_FOUND (0x80bb0001), component VirtualBoxWrap, interface IVirtualBox, callee nsISupports
VBoxManage: error: Context: "FindMachine(Bstr(a->argv[0]).raw(), machine.asOutParam())" at line 383 of file VBoxManageControlVM.cpp
######### .............. Done
######### unregister vm CentOS-7 and delete it
VBoxManage: error: Could not find a registered machine named 'CentOS-7'
VBoxManage: error: Details: code VBOX_E_OBJECT_NOT_FOUND (0x80bb0001), component VirtualBoxWrap, interface IVirtualBox, callee nsISupports
VBoxManage: error: Context: "FindMachine(Bstr(VMName).raw(), machine.asOutParam())" at line 153 of file VBoxManageMisc.cpp
No VM by name CentOS-7
######### Copy disk.vmdk created
######### Create vboxnet0 network and set dhcp server : 192.168.99.0/24
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
Interface 'vboxnet0' was successfully created
######### Create VM
Virtual machine 'CentOS-7' is created and registered.
UUID: e5ca6778-2405-40cf-ba4b-5843f2da802a
Settings file: '/Users/dabou/VirtualBox VMs/CentOS-7/CentOS-7.vbox'
######### Define NIC adapters; NAT and vboxnet0
######### Customize vm; ram, cpu, ....
######### Create IDE Controller, attach vmdk disk and iso dvd
######### start vm and configure SSH Port forward
Waiting for VM "CentOS-7" to power on...
VM "CentOS-7" has been successfully started.
```

**Note** : VirtualBox will fail to unregister and remove the vm the first time you execute the script; warning messages will be displayed!

Test if you can ssh to the newly created vm using the private address `192.168.99.50`!
```bash
ssh root@192.168.99.50     
The authenticity of host '192.168.99.50 (192.168.99.50)' can't be established.
ECDSA key fingerprint is SHA256:0yyu8xv/SD++5MbRFwc1QKXXgbV1AQOQnVf1YjqQkj4.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '192.168.99.50' (ECDSA) to the list of known hosts.

[root@cloud ~]# 
```

## Using Cloud Provider - Hetzner

See [hetzner](hetzner/README.md) page explaining how to create a cloud vm.

# Turn on your OpenShift machine into a cloud Native Dev environment 
## Bash script (minishift only)

**Note** : Due to the limitation explained within the introduction, we can't use ansible playbooks to configure some of the features proposed. 

We will then use the following bash script - `deploy_launcher_minishift.sh` instead to install the `Fabric8 launcher` and play with missions / boosters.
Using this script, you will have to specify your OpenShift account user/password and also your github user and API access token ([get an access token here](https://github.com/settings/tokens)).
This will enable you to use the `git flow` when running missions / boosters, rather than downloading boosters as zip files and deploying them manually.

```bash
cd minishift 
./deploy_launcher_minishift.sh -p projectName -i username:password -g myGithubUser:myGithubToken 

E.g ./deploy_launcher_minishift.sh -p devex -g myGithubUser:myGithubToken
```

## Ansible playbooks

See [Ansible post installation](ansible/README-post-installation.md) file to provision OpenShift with one of the Cloud Development features proposed.
 
