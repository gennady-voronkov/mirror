#!/bin/bash
#
# Author Gennady Voronkov
#
all_nodes="10.244.117.86 10.244.117.92 10.244.117.228 10.207.229.97 10.207.229.50 10.207.229.231"
for ip in ${all_nodes[*]}
do
    if ! ip -br a|grep UP|grep -q $ip; then
      ssh $ip mkdir -p /root/rancher
      scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      /root/stop.sh /root/start.sh /root/slave.sh /root/master.sh \
      /root/change_arecord.py /root/switchover.sh /root/syncfiles_req.sh \
      /root/nginx-latest-new.yml /root/run $ip:~/ 2>/dev/null

      scp /root/rancher/* $ip:/root/rancher/

      scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      /root/switchover.sh $ip:/usr/local/bin/switchover 2>/dev/null
    else
      scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      /root/switchover.sh $ip:/usr/local/bin/switchover 2>/dev/null
    fi
done
exit
