#!/bin/bash
set -xv
pod=$1
tracetime=30
workerip=$(kubectl get pod/$pod -n storobj-test -o json|grep '\"hostIP'|awk -F ':' '{print $2}'|awk -F ',' '{print $1}'|awk -F '"' '{print $2}')
container=$(kubectl get pod/$pod -n storobj-test -o json|grep -B 1 eric-data-object-storage-mn|grep containerID|awk -F'"docker://' '{print $2}'|awk -F '",' '{print $1}')
ifindex=$(ssh $workerip "sudo docker exec $container /bin/bash -c 'cat /sys/class/net/eth0/iflink'")
a=$(ssh $workerip "grep $ifindex /sys/class/net/*/ifindex")
interface=$(echo $a|awk -F '/sys/class/net/' '{print $2}'|awk -F '/ifindex' '{print $1}')
echo "BEFORE STARTING tcpdump $workerip"
ssh $workerip "sudo tcpdump --buffer-size=6144 -i $interface -s 0 -G $tracetime -W 1 -w ~/$pod.pcap" & 
echo "AFTER STARTING tcpdump"

#sleep 40
#workerip=$(kubectl get pod/$pod -n storobj-test -o json|grep '\"hostIP'|awk -F ':' '{print $2}'|awk -F ',' '{print $1}'|awk -F '"' '{print $2}')
#scp $workerip:~/$pod.pcap .


