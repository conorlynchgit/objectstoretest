#!/bin/bash
description() {
echo "########################################################################################################################"
echo "# HA test case for ObjectStore using default configuration (4 Servers/PODS , 1 disk per Server/POD                     #"
echo "#                                                                                                                      #"
echo "# Based on this configuration (https://min.io/product/erasure-code-calculator) the following failures can be tolerated #"
echo "# Write:Max failure tolerance is 1 disk/1 POD failure                                                                  #"
echo "# Read: Max failure tolerance is 2 disks/2 PODs failure                                                                #"
echo "########################################################################################################################"
}
write_upload() {
echo ""
echo "... Attempting to write test .."
kubectl -it exec pod/$testpod -c eosc -n $ns -- python3 /testSDK/file-uploader_tlsoff.py
echo "...Write Attempt complete..."
}
read_quick() {
echo -e "\n################################################################"
echo "###  Reading data Object from MN to test Client $testpod  ###"
echo "################################################################"
kubectl -it exec pod/$testpod -c eosc -n $ns -- python3 /testSDK/file-downloader_tlsoff.py
}
read_download() {
echo "... $numberPodsToDelete PODs are down..Attempting to read object .. "
kubectl -it exec pod/$testpod -c eosc -n $ns -- rm $downloadedfile >/dev/null 2>&1
echo "... ensure donwload file is not present"
kubectl -it exec pod/$testpod -c eosc -n $ns -- ls -ltr $downloadedfile
kubectl -it exec pod/$testpod -c eosc -n $ns -- python3 /testSDK/file-downloader_tlsoff.py
echo "... ensure donwload file is present"
kubectl -it exec pod/$testpod -c eosc -n $ns -- ls -ltr $downloadedfile
echo "...Read complete..."
set +xv
}

delete_pods_read() {
# Delete required PODS
echo "...Deleting $numberPodsToDelete PODS"
for j in {1..10};do
for ((i=0;i<=$numberPodsToDelete-1;i++)); do
echo "Re-Deleting mn-$i ..."
kubectl delete po/eric-data-object-storage-mn-$i -n $ns&
done
done
echo "done..."
}

setup_pullfailure_pods() {
# Delete required PODS
echo -e "\n#############################################################"
echo "### Creating image pull failure condition for $numberPodsToDelete POD(s) ###"
echo -e "#############################################################"
echo ""
for ((i=0;i<=$numberPodsToDelete-1;i++)); do
echo "Creating an image pull failure condition for  mn-$i ..."
# insert value 99 in front of image version, so inserts an image 'pull failure'
kubectl get po/eric-data-object-storage-mn-$i -n $ns -o yaml|sed 's/eric-data-object-storage-mn:/eric-data-object-storage-mn:99/'\
|kubectl replace -f -
done
echo "done..."
wait_for_pods_leaving_running
}


restore_pullfailure_pods() {
# Delete required PODS
echo ""
echo "... Restore POD back to Running state..."
for ((i=0;i<=$numberPodsToDelete-1;i++)); do
#kubectl delete po/eric-data-object-storage-mn-$i -n $ns&
# insert value 99 in front of image version, so inserts an image 'pull failure'
kubectl get po/eric-data-object-storage-mn-$i -n $ns -o yaml|sed 's/eric-data-object-storage-mn:99/eric-data-object-storage-mn:/'\
|kubectl replace -f -
done
echo "done..."
wait_all_pods_running
}

wait_for_pods_leaving_running() {
echo -e  "\n... Wait until $numberPodsToDelete/$replicas PODs are in Failure state ..."
statusAll="SomeRunning"
while [ $statusAll != "AllNotRunning" ];do
statusAll="AllNotRunning"
for ((i=0;i<=$numberPodsToDelete-1;i++)); do
status=$(kubectl get pod/eric-data-object-storage-mn-$i  -n $ns --no-headers=true|awk '{print $3}')
if [ "$status" == "Running" ];then
statusAll="SomeRunning"
fi
echo -n "."
done
done
echo -e "\n $numberPodsToDelete/$replicas PODs are in Failure state ..." 
}

clear_and_setup_pods_objects() {
echo ""
#echo ".... Removing '/export/testing/fileToUpload' test object from MN servers"
kubectl -it exec pod/$testpod -c eosc -n $ns -- python3 /testSDK/file-remove_tlsoff.py
#echo ".... Setup test file on testpod $testpod"
head -c $size"M" /dev/urandom > $testfile
kubectl cp $testfile $ns/$testpod:/fileToUpload.txt -c eosc >/dev/null 2>&1
#kubectl -it exec pod/$testpod -c eosc -n $ns -- ls -l /fileToUpload.txt
kubectl -it exec pod/$testpod -c eosc -n $ns -- rm $downloadedfile >/dev/null 2>&1
#echo " .... (reading test case..) Checking that /fileToDownload.txt is removed"
kubectl -it exec pod/$testpod -c eosc -n $ns -- ls -ltr /fileToDownload.txt >/dev/null 2>&1
}

wait_all_pods_running() {
echo ""
echo "...Waiting until all RUNNING...."
statusAll="NotRunning"
while [ $statusAll != "Running" ];do
statusAll="Running"
for ((i=0;i<=$replicas-1;i++)); do
status=$(kubectl get po/eric-data-object-storage-mn-$i -n $ns|grep eric-data-object-storage-mn-$i|awk '{print $3}')
if [ $status != "Running" ];then
statusAll="NotRunning"
fi
done
done
sleep 5
echo -e "  ... ALL MN PODS are back Running ...\n\n"
}

check_pods_write() {
echo "########################################"
echo "###   Data Upload status on each POD ###"
echo "########################################"
for ((i=0;i<=$replicas-1;i++)); do
echo " POD mn-$i ..."
kubectl -it exec pod/eric-data-object-storage-mn-$i -c eric-data-object-storage-mn -n $ns -- ls -lh /export/testing
echo ""
done

}

check_pods_read() {
echo -e "\n\n#################################################"
echo "### Check Data Download status on test client ###"
echo "#################################################"
kubectl -it exec pod/$testpod -c eosc -n $ns -- ls -ltr $downloadedfile
#kubectl -it exec pod/$testpod -c eosc -n $ns -- ls -ltr /
}

if [ -z $1 -o -z $2 ];then
echo "Usage: minio_ha.sh <number of PODs to delete> <read/write>"
exit 0
fi
numberPodsToDelete=$1
task=$2
ns=$3
replicas=4
size=10
if [ -z $ns ];then
echo "Using storobj-test as a namespace"
ns="storobj-test"
fi
downloadedfile="/fileDownloaded.txt"
testfile=./fileToUpload.txt
testpod=$(kubectl get pod -n $ns|grep test-obj-store|awk '{print $1}')
# common 
description
if [ $task == "write" ];then
 wait_all_pods_running
 clear_and_setup_pods_objects
 echo -e "\n ... Initial Data setup on PODs (before write attempt) ..." 
 check_pods_write
 sleep 5
 setup_pullfailure_pods
# wait_for_container_create_state
 exit 0
 write_upload
 restore_pullfailure_pods
 echo " Post Data setup on PODs (after write attempt)" 
 while [ true ];do
 date
 check_pods_write
 sleep 600 
 done
elif [ $task == "read" ];then
 wait_all_pods_running
 clear_and_setup_pods_objects
echo -e "\n ###################################"
 echo -e " ###  Setting up data on MN PODS ###"
echo -e " ###################################"
 write_upload
 echo -n "\n ... Initial Data setup on PODs (before read attempt)" 
 check_pods_read
 setup_pullfailure_pods
 read_quick
 check_pods_read
 restore_pullfailure_pods
fi
rm $testfile
