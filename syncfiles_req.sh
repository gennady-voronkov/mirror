#!/bin/bash
#
# Author Gennady Voronkov
#
file="$@"

all_nodes="10.244.117.86 10.244.117.92 10.244.117.228 10.207.229.97 10.207.229.50 10.207.229.231"
for ip in ${all_nodes[*]}
do
  for f in $file
  do
    if ! ip -br a|grep UP|grep -q $ip; then
      scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      $f $ip:$f 2>/dev/null
    else
      echo skip
    fi
  done
done
exit
