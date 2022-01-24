#!/bin/bash
mn="mn-0"
mgt="eric-data-object-storage-mn-mgt-7b895f579c-mtlsx"
testpod="test-obj-store-589875f95d-q84r9"
# get the mn servers first
for i in {0..3};do
workerip=$(kubectl get pod/eric-data-object-storage-mn-$i -n storobj-test -o json|grep '\"hostIP'|awk -F ':' '{print $2}'|awk -F ',' '{print $1}'|awk -F '"' '{print $2}')
container=$(kubectl get pod/eric-data-object-storage-mn-$i -n storobj-test -o json|grep containerID|awk -F'"docker://' '{print $2}'|awk -F '",' '{print $1}')
ifindex=$(ssh $workerip "sudo docker exec $container /bin/bash -c 'cat /sys/class/net/eth0/iflink'")
a=$(ssh $workerip "grep $ifindex /sys/class/net/*/ifindex")
interface=$(echo $a|awk -F '/sys/class/net/' '{print $2}'|awk -F '/ifindex' '{print $1}')
echo "Interface for mn-$1 is $interface"
ssh $workerip "sudo tcpdump --buffer-size=6144 -i $interface -s 0 -G 30 -W 1 -w ~/mn-$i.pcap" &
done
# get the mgt trace now
workerip=$(kubectl get pod/$mgt -n storobj-test -o json|grep '\"hostIP'|awk -F ':' '{print $2}'|awk -F ',' '{print $1}'|awk -F '"' '{print $2}')
container=$(kubectl get pod/$mgt -n storobj-test -o json|grep containerID|awk -F'"docker://' '{print $2}'|awk -F '",' '{print $1}')
ifindex=$(ssh $workerip "sudo docker exec $container /bin/bash -c 'cat /sys/class/net/eth0/iflink'")
a=$(ssh $workerip "grep $ifindex /sys/class/net/*/ifindex")
interface=$(echo $a|awk -F '/sys/class/net/' '{print $2}'|awk -F '/ifindex' '{print $1}')
echo "Interface for mgt is $interface"
ssh $workerip "sudo tcpdump --buffer-size=6144 -i $interface -s 0 -G 30 -W 1 -w ~/mgt.pcap" &

# get the testpod now
workerip=$(kubectl get pod/$testpod -n storobj-test -o json|grep '\"hostIP'|awk -F ':' '{print $2}'|awk -F ',' '{print $1}'|awk -F '"' '{print $2}')
container=$(kubectl get pod/$testpod -n storobj-test -o json|grep containerID|awk -F'"docker://' '{print $2}'|awk -F '",' '{print $1}')
# hardcoding
container="df366b64cde7ba2b11b7856fa048c30d38b35854839e87daddde4d5c2ffd5951"

ifindex=$(ssh $workerip "sudo docker exec $container /bin/bash -c 'cat /sys/class/net/eth0/iflink'")
a=$(ssh $workerip "grep $ifindex /sys/class/net/*/ifindex")
interface=$(echo $a|awk -F '/sys/class/net/' '{print $2}'|awk -F '/ifindex' '{print $1}')
echo "Interface for testood is $interface"
ssh $workerip "sudo tcpdump --buffer-size=6144 -i $interface -s 0 -G 30 -W 1 -w ~/testclient.pcap" &




echo "All TCPDUMPS have been ordered (for 30 secs)...Run your test now...will collect logs in 30 seconds.."
sleep 40
for i in {0..3};do
workerip=$(kubectl get pod/eric-data-object-storage-mn-$i -n storobj-test -o json|grep '\"hostIP'|awk -F ':' '{print $2}'|awk -F ',' '{print $1}'|awk -F '"' '{print $2}')
scp $workerip:~/mn-$i.pcap .
done
# mgt
echo "MGT get pcap file..."
workerip=$(kubectl get pod/$mgt -n storobj-test -o json|grep '\"hostIP'|awk -F ':' '{print $2}'|awk -F ',' '{print $1}'|awk -F '"' '{print $2}')
scp $workerip:~/mgt.pcap .

echo "test pod"
workerip=$(kubectl get pod/$testpod -n storobj-test -o json|grep '\"hostIP'|awk -F ':' '{print $2}'|awk -F ',' '{print $1}'|awk -F '"' '{print $2}')
scp $workerip:~/testclient.pcap .


