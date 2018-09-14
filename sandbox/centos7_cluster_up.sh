#!/usr/bin/env bash

#
# Command to provision a centos7 vm using virtualbox driver
# with oc cluster up
#
echo "=================="
echo "Reset ssh key"
echo "=================="
ssh-keygen -R 192.168.99.50
echo "===================="
echo "Create Virtualbox VM"
echo "===================="
./virtualbox/create-vm.sh -i ~/images -m 5000 -n dummy
sleep 5m
echo "============================================="
echo "Execute shell script to perform oc cluster up"
echo "============================================="
ssh -o StrictHostKeyChecking=no root@192.168.99.50 'bash -s' < sandbox/cluster_up.sh
