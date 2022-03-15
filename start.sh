#!/bin/bash
#
#Author Gennady Voronkov
#
#
/root/master.sh
sleep 1
if grep -q "dur" /root/location
  then
    if grep -q etcd1 /etc/hostname
      then
        sed -i 's/10.244.117.86/10.207.229.97/g' /etc/kubernetes/manifests/kube-apiserver.yaml
        sed -i 's/10.244.117.86/10.207.229.97/g' /etc/kubernetes/scheduler.conf
        sed -i 's/10.244.117.86/10.207.229.97/g' /etc/kubernetes/controller-manager.conf
      elif grep -q etcd2 /etc/hostname
        then
          sed -i 's/10.244.117.92/10.207.229.50/g' /etc/kubernetes/manifests/kube-apiserver.yaml
          sed -i 's/10.244.117.92/10.207.229.50/g' /etc/kubernetes/scheduler.conf
          sed -i 's/10.244.117.92/10.207.229.50/g' /etc/kubernetes/controller-manager.conf
        elif grep -q etcd3 /etc/hostname
          then
            sed -i 's/10.244.117.228/10.207.229.231/g' /etc/kubernetes/manifests/kube-apiserver.yaml
            sed -i 's/10.244.117.228/10.207.229.231/g' /etc/kubernetes/scheduler.conf
            sed -i 's/10.244.117.228/10.207.229.231/g' /etc/kubernetes/controller-manager.conf
    fi
  elif grep -q "hop" /root/location
    then
      if grep -q etcd1 /etc/hostname
        then
          sed -i 's/10.207.229.97/10.244.117.86/g' /etc/kubernetes/manifests/kube-apiserver.yaml
          sed -i 's/10.207.229.97/10.244.117.86/g' /etc/kubernetes/scheduler.conf
          sed -i 's/10.207.229.97/10.244.117.86/g' /etc/kubernetes/controller-manager.conf
        elif grep -q etcd2 /etc/hostname
          then
            sed -i 's/10.207.229.50/10.244.117.92/g' /etc/kubernetes/manifests/kube-apiserver.yaml
            sed -i 's/10.207.229.50/10.244.117.92/g' /etc/kubernetes/scheduler.conf
            sed -i 's/10.207.229.50/10.244.117.92/g' /etc/kubernetes/controller-manager.conf
          elif grep -q etcd3 /etc/hostname
            then
              sed -i 's/10.207.229.231/10.244.117.228/g' /etc/kubernetes/manifests/kube-apiserver.yaml
              sed -i 's/10.207.229.231/10.244.117.228/g' /etc/kubernetes/scheduler.conf
              sed -i 's/10.207.229.231/10.244.117.228/g' /etc/kubernetes/controller-manager.conf
      fi
    else
      echo "nonename"
fi

sleep 2
systemctl start etcd
sleep 1
systemctl start docker
sleep 1
systemctl start kubelet
sleep 1

exit
