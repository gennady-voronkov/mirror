#!/bin/bash
#
#Author Gennady Voronkov
#
#
systemctl stop kubelet
sleep 1
systemctl stop docker
sleep 1
systemctl stop etcd
sleep 1
/root/slave.sh

exit

