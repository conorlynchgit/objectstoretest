#!/bin/bash
set -xv
pod=$1
cont=$2
ns=$3

tracetime=30
workerip=$(kubectl get pod/$pod -n $ns -o json|grep '\"hostIP'|awk -F ':' '{print $2}'|awk -F ',' '{print $1}'|awk -F '"' '{print $2}')
container=$(kubectl describe pod/$pod -n $ns|grep -A 1 $cont:|grep 'Container ID'|awk -F 'containerd://' '{print $2}')
#container=$(kubectl get pod/$pod -n $ns -o json|grep -B 1 eric-data-object-storage-mn|grep containerID|awk -F'"docker://' '{print $2}'|awk -F '",' '{print $1}')
ifindex=`kubectl -it exec po/$pod -c $cont -n $ns -- cat -T /sys/class/net/eth0/iflink`
ifindex2=`echo $ifindex|sed 's/\\r$//'`
ifindex=$ifindex2
#ifindex=$(ssh $workerip "sudo docker exec $container /bin/bash -c 'cat /sys/class/net/eth0/iflink'")
a=$(ssh -oStrictHostKeyChecking=no $workerip "grep -w $ifindex /sys/class/net/*/ifindex")
interface=$(echo $a|awk -F '/sys/class/net/' '{print $2}'|awk -F '/ifindex' '{print $1}')
echo "STARTING tcpdump for 30 seconds It will be created $workerip at /$pod.pcap"
ssh -oStrictHostKeyChecking=no $workerip "sudo tcpdump --buffer-size=6144 -i $interface -s 0 -G $tracetime -W 1 -w ~/$pod.pcap" & 
#sleep $tracetime
#workerip=$(kubectl get pod/$pod -n storobj-test -o json|grep '\"hostIP'|awk -F ':' '{print $2}'|awk -F ',' '{print $1}'|awk -F '"' '{print $2}')
#scp $workerip:~/$pod.pcap .


