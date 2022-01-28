#!/bin/bash

write_upload() {
echo "... Attempting to write data .."
kubectl -it exec pod/$testpod -c eosc -n $ns -- python3 /testSDK/file-uploader_tlsoff.py
echo "...Write Attempt complete..."
}

read_download() {
echo "... $numberPodsToDelete PODs are down..Attempting to read object .. "
kubectl -it exec pod/$testpod -c eosc -n $ns -- python3 /testSDK/file-downloader_tsloff.py
echo "...Read complete..."
}
delete_pods_read() {
# Delete required PODS
echo "...Deleting $numberPodsToDelete PODS"
for j in {1..2};do
for ((i=0;i<=$numberPodsToDelete-1;i++)); do
echo "Deleting mn-$i ..."
kubectl delete po/eric-data-object-storage-mn-$i -n $ns&
done
done
echo "done..."
}
delete_pods() {
# Delete required PODS
echo "...Deleting $numberPodsToDelete PODS"
for ((i=0;i<=$numberPodsToDelete-1;i++)); do
echo "Deleting mn-$i ..."
kubectl delete po/eric-data-object-storage-mn-$i -n $ns
done
echo "done..."
}
wait_for_container_create_state() {
echo "Wait until deleted pods are re-initialising"
statusAll="NotContainerCreating"
echo "Waiting for all deleted PODs to come back into ContainerCreating state..."
while [ $statusAll != "ContainerCreating" ];do
statusAll="ContainerCreating"
for ((i=0;i<=$numberPodsToDelete-1;i++)); do
status=$(kubectl get pod/eric-data-object-storage-mn-$i  -n $ns --no-headers=true|awk '{print $3}')
if [ $status != "ContainerCreating" ];then
statusAll="NotContainerCreating"
fi
echo -n "."
done
done
echo ""
# echo out state of PODS before test starts
echo "... Deleted PODS are now ready to start again"
for ((i=0;i<=$numberPodsToDelete-1;i++)); do
status=$(kubectl get pod/eric-data-object-storage-mn-$i  -n $ns --no-headers=true|awk '{print $3}')
echo "\nPOD mn-$i is in state $status"
done
}

clear_and_setup_pods_objects() {
echo ""
echo "... Clearing Test DATA from test POD $testpod"
echo ".... Removing test object file from MN servers (fileToUpload)"
kubectl -it exec pod/$testpod -c eosc -n storobj-test -- python3 /testSDK/file-remove_tlsoff.py
echo ".... Setup test files on testpod $testpod"
head -c $size"M" /dev/urandom > $testfile
kubectl cp $testfile $ns/$testpod:/fileToUpload.txt -c eosc
kubectl -it exec pod/$testpod -c eosc -n $ns -- ls -l /fileToUpload.txt
kubectl -it exec pod/$testpod -c eosc -n $ns -- rm /fileToDownload.txt >/dev/null 2>&1
echo " .... Checking that /fileToDownload.txt is removed"
kubectl -it exec pod/$testpod -c eosc -n $ns -- ls -ltr /fileToDownload.txt >/dev/null 2>&1
}
wait_all_pods_running() {
echo "...Waiting until all RUNNING...."
statusAll="NotRunning"
while [ $statusAll != "Running" ];do
statusAll="Running"
for ((i=0;i<=$replicas-1;i++)); do
status=$(kubectl get -o template pod/eric-data-object-storage-mn-$i --template={{.status.phase}} -n $ns)
if [ $status != "Running" ];then
statusAll="NotRunning"
fi
done
done
kubectl get po -n $ns
}
check_pods() {
echo ""
echo "... Data Upload status on each POD ...\n"
for ((i=0;i<=$replicas-1;i++)); do
echo " POD mn-$i ..."
kubectl -it exec pod/eric-data-object-storage-mn-$i -c eric-data-object-storage-mn -n $ns -- ls -lh /export/testing
echo ""
done
echo "... Data Download status on test client"
kubectl -it exec pod/$testpod -c eosc -n $ns -- ls -ltr /|grep fileToDownload.txt
}
if [ -z $1 -o -z $2 ];then
echo "Usage: minio_ha.sh <number of PODs to delete> <read/write>"
exit 0
fi
numberPodsToDelete=$1
task=$2
replicas=4
size=10
ns=storobj-test
testfile=./fileToUpload.txt
testpod=$(kubectl get pod -n $ns|grep test-obj-store|awk '{print $1}')
# common 
if [ $task == "write" ];then
wait_all_pods_running
clear_and_setup_pods_objects
check_pods
delete_pods
wait_for_container_create_state
write_upload
wait_all_pods_running
check_pods
elif [ $task == "read" ];then
wait_all_pods_running
clear_and_setup_pods_objects
check_pods
#setup data for the read
write_upload
wait_all_pods_running
check_pods
echo "...Now write data should be in place..delete pods and attempt a read"
delete_pods
wait_for_container_create_state
delete_pods&
read_download
wait_all_pods_running
check_pods
fi
rm $testfile
