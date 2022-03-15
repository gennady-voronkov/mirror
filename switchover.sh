#!/bin/bash
#
#Author Gennady Voronkov
#
#
LOCALHOST=$(hostname -f)
STATUS="0"
usage() {
  typeset -l prog="${1:-switchover}"
  echo "Usage: $prog --h                Print this help and exit"
  echo "Usage: $prog [--switchto <host>] [--status] and so on";
  echo "--switchto        <host>         Switchover to remote node"
  echo "--status                         Status of local/remote node"
  echo "--switchto                       Manual Switchover"
}

check_status() {
  role="unknown"
  ip=$1
  role=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $ip /usr/sbin/drbdadm status mirror 2>/dev/null|grep mirror|cut -d: -f2)
  if [ -z "$role" ]
    then
      role="$role"
  fi
  echo $role
}

whereisit() {
  vip_name="rancher-new.k8s.cec.lab.emc.com"

  if host $vip_name|grep -q "10.244.118.5"; then
    loc='Hopkinton'
    echo "$loc:Durham:10.207.229.64"
  elif host $vip_name|grep -q "10.207.229.64"; then
    loc='Durham'
    echo "$loc:Hopkinton:10.244.118.5"
  else
    echo "Can not identify where we are"
    exit 1
  fi

}

neighbour() {
  loc="$1"
  if [ "$loc" == "Hopkinton" ]
    then
      Hopkinton="10.244.117.86 10.244.117.92 10.244.117.228"
      echo "$Hopkinton"
    elif [ "$loc" == "Durham" ]
      then
        Durham="10.207.229.97 10.207.229.50 10.207.229.231"
        echo "$Durham"
  fi
}

isitip() {
  stat=1
  if echo "$1"|grep -Eqo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'
    then
      stat=$?
  fi
  return $stat
}

if [ -z "$*" ]
  then
    echo "No options found!"
    usage $0
    exit 1
fi

while [[ $# -ge 1 ]]
do
  case $1 in
    --h) usage $0
         exit 3
         ;;
    --status)
         STATUS="1"
         ;;
    --switchto)
         SWITCHTO="$2"
         shift
         ;;
    *) usage $0
       exit 1
       ;;
  esac
shift
done

trap -p SIGINT SIGQUIT SIGTERM

if [ "$STATUS" == "1" -a -z "$SWITCHTO" ]
  then
    echo "Current node($LOCALHOST) is - $(check_status 127.0.0.1)"
    exit 0
fi

if [ -n "$SWITCHTO" -a "$STATUS" == "1" ]
  then
    if isitip $SWITCHTO
      then
        if ip -br a|grep UP|grep -q $SWITCHTO
          then
            echo "It's current node($SWITCHTO) is - $(check_status $SWITCHTO)"
          else
            echo "Remote node($SWITCHTO) is - $(check_status $SWITCHTO)"
        fi
      else
        echo -e "Could you please provide IP address"
    fi
  exit 0
fi

if [ -z "$SWITCHTO" -a "$STATUS" = "0" ]
  then
    loc=$(whereisit)
    echo -e "Right now K8S is woring in - `echo $loc|cut -d: -f1`"

    read -p "Would You like to switch Kubernetes cluster over from `echo $loc|cut -d: -f1` to `echo $loc|cut -d: -f2` (Y/n) [n]? " line
    switchto=${line:-n}
    switchto="$(echo $switchto | tr '[:upper:]' '[:lower:]')"

    if [[ ! $switchto =~ ^(yes|y)$ ]]
      then
        echo "Exiting now!"
        exit 1
    fi
    loc_from=`echo $loc|cut -d: -f1`
    loc_to=`echo $loc|cut -d: -f2`
    vip=`echo $loc|cut -d: -f3`
    vip_name="rancher-new.k8s.cec.lab.emc.com"
    from_neighbour=$(neighbour $loc_from)
    to_neighbour=$(neighbour $loc_to)
    # stop k8s
    for ip in ${from_neighbour[*]}
    do
      ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $ip "/root/stop.sh" 2>/dev/null &
      #ssh $ip "date && date" &
      echo "Node $ip has stopped"
    done
    sleep 40
    for ip in ${from_neighbour[*]}
    do
      echo "$ip in $loc_from location now - $(check_status $ip)"
    done

    sleep 1

    # start k8s
    for ip in ${to_neighbour[*]}
    do
      ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $ip "/root/start.sh" 2>/dev/null &
      #ssh $ip "date && date" &
      echo "Node $ip has started"
    done
    sleep 40
    for ip in ${to_neighbour[*]}
    do
      echo "$ip in $loc_to location now - $(check_status $ip)"
    done

    # Switch over FQDN name
    python3 /root/change_arecord.py $vip rancher-new |awk -F, '{print $2}'
    sleep 2

    # Check dns
    while true
    do
      if host $vip_name|grep -q $vip; then
        break
      else
        echo "VIP name has not been moved to another network, waiting ..."
        sleep 20
      fi
    done
    echo "VIP name has got right ip address"

    # Check api-server
    while true
    do
      http_code=$(curl -s -k -w "%{http_code}" https://$vip_name:6443/healthz --connect-timeout 3 -o /dev/null)
      if [[ $http_code -ne 200 ]]; then
        echo "API server is still in progress - `date --utc +%Y-%m-%d_%H-%M-%S`"
        sleep 30
      else
        echo "API server is working - `date --utc +%Y-%m-%d_%H-%M-%S`"
        break
      fi
    done

    # Check k8s cluster
    while true
    do
      sleep 30
      pods_status=$(ssh $vip "kubectl get pods -A --field-selector=status.phase!=Running" 2>&1)
      if [ "$pods_status" == "No resources found" ]; then
        echo "Cluster Up and Running"
        break
      else
        echo "$pods_status"
      fi
    done

  else
    if isitip $SWITCHTO
      then
        SWITCH_IP=$SWITCHTO
      else
        echo -e "Could you please provide IP address"
        exit 1
    fi


    if ! ip -br a|grep UP|grep -q $SWITCH_IP
      then
        echo "notlocal"
        if [ "127.0.0.1" != "$SWITCH_IP" ]
          then
            echo switchover
            #/root/stop.sh
            #ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${SWITCH_IP} /root/start.sh 2>/dev/null
          else
            echo -e "You are trying to switch current host over to local node\n"
        fi
      else
        echo "please specify remote ip address"
    fi
fi

exit
