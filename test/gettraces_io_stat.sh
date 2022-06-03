#!/bin/bash
set -xv
ns=$1
replicas=4
for ((i=0;i<=$replicas-1;i++)); do
pod="eric-data-object-storage-mn-$i"
fs=$(kubectl exec pod/$pod -n $ns -- df -h /export|egrep -v "Filesystem"|awk '{print $1}')
workerip=$(kubectl get pod/$pod -n $ns -o json|grep '\"hostIP'|awk -F ':' '{print $2}'|awk -F ',' '{print $1}'|awk -F '"' '{print $2}')
ssh -oStrictHostKeyChecking=no $workerip "iostat -hxym $fs 1 >/tmp/iostat$i " &
done
echo "When done press a key"
read a
for ((i=0;i<=$replicas-1;i++)); do
pod="eric-data-object-storage-mn-$i"
workerip=$(kubectl get pod/$pod -n $ns -o json|grep '\"hostIP'|awk -F ':' '{print $2}'|awk -F ',' '{print $1}'|awk -F '"' '{print $2}')
iostatprocs=$(ssh -oStrictHostKeyChecking=no $workerip "pgrep iostat")
for iostatps in `echo $iostatprocs`;do
ssh -oStrictHostKeyChecking=no $workerip "kill -9 $iostatps"
done
echo "get /tmp/iostat$i">./batchfile
echo "bye">>./batchfile
sftp -b ./batchfile $workerip
done


