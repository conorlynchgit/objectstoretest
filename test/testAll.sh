#!/bin/bash
usage() {
echo "Usage .. "
echo "-s 'tls-on/tls-off' (TLS on or off)"
echo "-c 'dist/sa' (Configuration is Distributed or Standalone"
echo "-t 'def/chg' (TCP settings as Default or Changed"
echo "-n 'same/notsame (Only test Standalone using different nodes or same node)"
echo "-m '5120Mi' (example memory size limits of POD)"
echo "-p '4000m' (exeample CPU size limits of POD)"
echo "-a '3' (number of parallel TCP sessions (default 3))"
echo "-l '200' (example 200MB part size (default is 5MB)"
echo "-d 'yes' (create debug logs )"
echo "-f '200' (size of file (MB) to create )"
echo "-e 'testnamespace' ( namespace )"
echo "-r 'Object store main release (11 / 14)"
echo "-x 'yes' (if there is an existing deployment for testing)"
}
mgt_trace_setup() {
accesskey=$(kubectl exec pod/$mgtpod -c manager -n $ns -- printenv MINIO_ACCESS_KEY)
secretkey=$(kubectl exec pod/$mgtpod -c manager -n $ns -- printenv MINIO_SECRET_KEY)
tls=$(kubectl exec pod/$mgtpod -c manager -n $ns -- printenv TLS_ENABLED)
if [ $tls == false ]; then
scheme="http"
else
scheme="https"
fi
kubectl exec pod/$mgtpod -c manager -n $ns  -- bash -c "mc config --insecure host add myminio $scheme://eric-data-object-storage-mn:9000 $accesskey $secretkey"
kubectl exec pod/$mgtpod -c manager -n $ns  -- bash -c "rm -rf /tmp/my-serverconfig"
kubectl exec pod/$mgtpod -c manager -n $ns  -- bash -c "rm -rf /tmp/lock_info"
kubectl exec pod/$mgtpod -c manager -n $ns  -- bash -c "rm -rf /tmp/tracefile"
kubectl exec pod/$mgtpod -c manager -n $ns  -- bash -c "mc admin config export myminio > /tmp/my-serverconfig"
kubectl exec pod/$mgtpod -c manager -n $ns  -- bash -c "mc admin top locks myminio >/tmp/lock_info"
kubectl exec pod/$mgtpod -c manager -n $ns  -- bash -c "cd ~; mc admin profile start myminio/"
kubectl exec pod/$mgtpod -c manager -n $ns  -- bash -c "mc admin --insecure trace --debug myminio >/tmp/tracefile" &
# sleep for 30 seconds?
#kubectl exec pod/$mgtpod -c manager -n $ns  -- bash -c "cd ~;mc admin profile stop myminio/"
}

mgt_trace_copy_cleanup() {
kubectl exec pod/$mgtpod -c manager -n $ns  -- bash -c "cd ~;mc admin profile stop myminio/"
pids=$(kubectl exec pod/$mgtpod -c manager -n $ns -- bash -c "ps -ef|grep tracefile|egrep -v 'grep'"|awk '{print $2}')

for pid in `echo $pids`;do
kubectl exec pod/$mgtpod -c manager -n $ns -- bash -c "kill -9 $pid"
done

pids=$(kubectl exec pod/$mgtpod -c manager -n $ns -- bash -c "ps -ef|grep 'mc admin --insecure --debug trace -v -all myminio'|egrep -v 'grep'"|awk '{print $2}')
for pid in `echo $pids`;do
kubectl exec pod/$mgtpod -c manager -n $ns -- bash -c "kill -9 $pid"
done

kubectl cp $ns/$mgtpod:/tmp/my-serverconfig -c manager $servertmp/my-serverconfig
kubectl cp $ns/$mgtpod:/tmp/lock_info -c manager $servertmp/lock_info
kubectl cp $ns/$mgtpod:/tmp/tracefile -c manager $servertmp/tracefile
kubectl cp $ns/$mgtpod:/minio/profile.zip -c manager $servertmp/profile.zip
}
create_test_file() {

rm $testfile >/dev/null 2>&1
testfile="$basedir/fileToUpload.txt"
head -c $size"M" /dev/urandom > $testfile
#result=$(( 3000 * $size ))
#rm $testfile >/dev/null 2>&1
#for ((i = 0 ; i <= $result ; i++)); do
#echo "###########################################################################################################">>$testfile
#echo "###################################### line $i ########################################################################">>$testfile
#echo "####################################################################################################################">>$testfile
#done
}



update_min_max() {
# check the current MB/s value, and compare with the MIN and MAX values obtained for this test case
# If a new MIN or MAX, then overwrite the previous (tcpdump) file
#echo "ABOUT TO START MIN MAX"
#read a

ls $mindir/*$tcpfile* >/dev/null 2>&1
fileexists=$?
if [ $fileexists == 0 ];then
 echo "min file exists"
# compare the current mbs with mbs from MIN dir
 cd $mindir
 mbsmin=$(ls |grep $tcpfile|awk -F 'mbs' '{print $1}')

  if (( $(echo "$current_time < $mbsmin"|bc -l) )); then
  \rm -rf $mindir/*$tcpfile*
  \rm -rf $mindir/*$tcpfile"Server_traces" >/dev/null 2>&1 
    if [ $debug == "yes" ];then
    #kubectl cp $ns/$testpod:/$tcpfile $mindir/$current_time"mbs__"$tcpfile -c tcpdump
    #mkdir $mindir/$current_time"mbs__"$tcpfile"Server_traces" >/dev/null 2>&1 
    mkdir $mindir/$current_time"mbs__"$tcpfile"Server_traces" 
    echo "NEW DIR created"
    ls $mindir/ 
 # copy server tcpdumps
    cp $servertmp/* $mindir/$current_time"mbs__"$tcpfile"Server_traces" 
    else
    touch $mindir/$current_time"mbs__"$tcpfile
    fi

    echo "**** NEW MIN of $current_time mbs for test $tcpfile">>$result_file
   fi
else
echo "min file NOT exists"
# so just copy this current to be the min value now

 if [ $debug == "yes" ]; then
 # kubectl cp $ns/$testpod:/$tcpfile $mindir/$current_time"mbs__"$tcpfile -c tcpdump
  mkdir $mindir/$current_time"mbs__"$tcpfile"Server_traces" >/dev/null 2>&1
# copy server tcpdumps
  cp $servertmp/* $mindir/$current_time"mbs__"$tcpfile"Server_traces"
 else
  touch $mindir/$current_time"mbs__"$tcpfile
 fi
# record this timing
fi
# check against MAX values
ls $maxdir/*$tcpfile* >/dev/null 2>&1
fileexists=$?
if [ $fileexists == 0 ];then
 echo "max file exists"
# compare the current mbs with mbs from MAx dir
 cd $maxdir
 mbsmax=$(ls |grep $tcpfile|awk -F 'mbs' '{print $1}')
 if (( $(echo "$current_time > $mbsmax"|bc -l) )); then
  \rm -rf $maxdir/*$tcpfile*
  \rm -rf $maxdir/*$tcpfile"Server_traces" >/dev/null 2>&1 

  if [ $debug == "yes" ];then
   #kubectl cp $ns/$testpod:/$tcpfile $maxdir/$current_time"mbs__"$tcpfile -c tcpdump
   mkdir $maxdir/$current_time"mbs__"$tcpfile"Server_traces" >/dev/null 2>&1 
   cp $servertmp/* $maxdir/$current_time"mbs__"$tcpfile"Server_traces" 
  else
    touch $maxdir/$current_time"mbs__"$tcpfile
  fi

 echo "**** NEW MAX of $current_time mbs for test $tcpfile">>$result_file
 fi
else
echo "max file NOT exists"
# so copy this current to be the max value now
 if [ $debug == "yes" ]; then
 # kubectl cp $ns/$testpod:/$tcpfile $maxdir/$current_time"mbs__"$tcpfile -c tcpdump
  mkdir $maxdir/$current_time"mbs__"$tcpfile"Server_traces" >/dev/null 2>&1
# copy server tcpdumps
  cp $servertmp/* $maxdir/$current_time"mbs__"$tcpfile"Server_traces"
 else
  touch $maxdir/$current_time"mbs__"$tcpfile
 fi
fi
#echo "ABOUT TI FINISH"
#read a
}
create_mn_standalone() {
replicas=1
helm uninstall eric-data-object-storage-mn -n $ns >/dev/null 2>&1 
sleep 60
for i in $(kubectl get pvc -n $ns|grep 'data-object-storage'|awk '{print $1}');do
kubectl delete pvc $i -n $ns >/dev/null 2>&1
done
sleep 60
helm install eric-data-object-storage-mn $helm_rel --namespace=$ns --set server.resources.limits.memory=$memlimits --set server.resources.limits.cpu=$cpulimits --namespace=$ns --set mode=standalone --set replicas=1 $local_secret --set autoEncryption.enabled=true --set global.security.tls.enabled=true --set persistentVolumeClaim.size=40Gi
#--set server.resources.limits.memory=$memlimits --set server.resources.limits.cpu=$cpulimits
#helm install eric-data-object-storage-mn /home/eccd/conor/test/mn/eric-data-object-storage-mn --set server.resources.requests.memory=256Mi --set server.resources.requests.cpu=250m --namespace=$ns --set mode=standalone --set replicas=1 --set credentials.kubernetesSecretName=test-secret --set autoEncryption.enabled=true --set global.security.tls.enabled=true --set persistentVolumeClaim.size=40Gi
sleep 60
status=$(kubectl get -o template pod/eric-data-object-storage-mn-0 --template={{.status.phase}} -n $ns)
echo "Status of MN-0 POD is " $status
echo "Status of MN-0 POD is " $status
while [ $status != "Running" ];do
echo "MN-0 not running yet..."
status=$(kubectl get -o template pod/eric-data-object-storage-mn-0 --template={{.status.phase}} -n $ns)
echo "Status of MN-0 is " $status
sleep 60
done
echo "Mn-0 is running"
echo "#################################################################" >> $result_file
echo "################      Standalone:::TLS=ON             ###########" >> $result_file
echo "#################################################################" >> $result_file
}
create_mn_standalone_tlsoff() {
replicas=1
helm uninstall eric-data-object-storage-mn -n $ns >/dev/null 2>&1
sleep 20
kubectl delete pvc export-eric-data-object-storage-mn-0 -n $ns >/dev/null 2>&1
kubectl delete pvc export-eric-data-object-storage-mn-1 -n $ns >/dev/null 2>&1
kubectl delete pvc export-eric-data-object-storage-mn-2 -n $ns >/dev/null 2>&1
kubectl delete pvc export-eric-data-object-storage-mn-3 -n $ns >/dev/null 2>&1
sleep 60


clearnodes
if [ $1 == "same" ];then
node=$selectednode
kubectl label nodes $node allpodstogether=sure
affinity="--set nodeSelector.allpodstogether=sure"
antiaffinity='--set affinity.podAntiAffinity=""'
fi

helm install eric-data-object-storage-mn $helm_rel --namespace=$ns --set mode=standalone --set replicas=1 $memsetres $cpusetres $memsetlimit $cpusetlimit $local_secret --set autoEncryption.enabled=false --set global.security.tls.enabled=false --set persistentVolumeClaim.size=40Gi
#helm install eric-data-object-storage-mn $helm_rel --namespace=$ns --set mode=standalone --set replicas=1 $memsetres $cpusetres $memsetlimit $cpusetlimit --set credentials.kubernetesSecretName=test-secret --set autoEncryption.enabled=false --set global.security.tls.enabled=false --set persistentVolumeClaim.size=40Gi $affinity $antiaffinity
sleep 60
# initial status
#sleep 300
sleep 60
status=$(kubectl get -o template pod/eric-data-object-storage-mn-0 --template={{.status.phase}} -n $ns)
echo "Status of MN-0 POD is " $status
while [ $status != "Running" ];do
echo "MN-0 not running yet..."
status=$(kubectl get -o template pod/eric-data-object-storage-mn-0 --template={{.status.phase}} -n $ns)
echo "Status of MN-0 is " $status
sleep 60
done
echo "Mn-0 is running"
echo "###########################################################" >> $result_file
echo "################      Standalone:::TLS=OFF             ###########" >> $result_file
echo "###########################################################" >> $result_file
}

create_mn_distributed() {
if [ $1 == "tls-off" ]; then
create_mn_distributed_tlsoff $2
else
create_mn_distributed_tlson $2
fi
}
create_mn_distributed_tlson() {
# setup SIPTLS etc
kubectl create secret generic eric-data-distributed-coordinator-creds --namespace $ns --from-literal=etcdpasswd=$(echo -n "Cody1357" | base64)
helm upgrade --install eric-sec-sip-tls-crd \
        https://arm.sero.gic.ericsson.se/artifactory/proj-adp-gs-released-helm/eric-sec-sip-tls-crd/eric-sec-sip-tls-crd-2.5.0+27.tgz \
        --namespace $ns \
        --atomic
kubectl get crd -o custom-columns=name:metadata.name \
     | grep -E "com.ericsson.sec.tls|siptls.sec.ericsson.com"

helm install eric-data-distributed-coordinator-ed https://arm.sero.gic.ericsson.se/artifactory/proj-adp-gs-all-helm/eric-data-distributed-coordinator-ed/eric-data-distributed-coordinator-ed-3.0.0-9.tgz  --namespace=$ns
helm install eric-sec-sip-tls https://arm.sero.gic.ericsson.se/artifactory/proj-adp-gs-all-helm/eric-sec-sip-tls/eric-sec-sip-tls-3.1.0-36.tgz  --namespace=$ns
helm install eric-sec-key-management https://arm.sero.gic.ericsson.se/artifactory/proj-adp-gs-all-helm/eric-sec-key-management/eric-sec-key-management-3.0.0-8.tgz --set persistence.type=etcd --namespace=$ns

# wait until all pods starting

statusAll="NotRunning"
while [ $statusAll != "Running" ];do
listt=`kubectl get po -n $ns|egrep -v 'test|STATUS'|awk '{print $3}'`
sleep 30
statusAll="Running"
 for status in `echo $listt`;do
  if [ $status != "Running" ];then
   statusAll="NotRunning"
  fi
 done
done

affinity=""
helm uninstall eric-data-object-storage-mn -n $ns >/dev/null 2>&1
sleep 30
echo "Removing any old ObjectStore Pods and PVC's">>$result_file
for i in $(kubectl get pvc -n $ns|grep 'data-object-storage'|awk '{print $1}');do
kubectl delete pvc $i -n $ns >/dev/null 2>&1
done
sleep 60
clearnodes
if [ $1 == "same" ];then
node=$selectednode
kubectl label nodes $node allpodstogether=sure
affinity="--set nodeSelector.allpodstogether=sure"
antiaffinity='--set affinity.podAntiAffinity=""'
fi
helm install --debug eric-data-object-storage-mn $helm_rel --namespace=$ns --set drivesPerNode=$drives $local_secret --set replicas=$replica $memsetres $cpusetres $memsetlimit $cpusetlimit --set autoEncryption.enabled=true --set global.security.tls.enabled=true --set persistentVolumeClaim.size=60Gi $affinity $antiaffinity
sleep 60

echo "Helm installed ObjectStore .. waiting to come up...">>$result_file
statusAll="NotRunning"
while [ $statusAll != "Running" ];do
sleep 30
statusAll="Running"
for ((i=0;i<=replicas-1;i++)); do
status=$(kubectl get -o template pod/eric-data-object-storage-mn-$i --template={{.status.phase}} -n $ns)
if [ $status != "Running" ];then
statusAll="NotRunning"
fi
done
done
echo "All MN servers are  running..."
echo "############################################################" >> $result_file
echo "#########     Distributed:TLS-ON                 ###########" >> $result_file
echo "############################################################" >> $result_file
}


create_mn_distributed_tlsoff() {
affinity=""
helm uninstall eric-data-object-storage-mn -n $ns >/dev/null 2>&1
sleep 30
echo "Removing any old ObjectStore Pods and PVC's">>$result_file 
for i in $(kubectl get pvc -n $ns|grep 'data-object-storage'|awk '{print $1}');do
kubectl delete pvc $i -n $ns >/dev/null 2>&1
done
sleep 60 
clearnodes
if [ $1 == "same" ];then
node=$selectednode
kubectl label nodes $node allpodstogether=sure
affinity="--set nodeSelector.allpodstogether=sure"
antiaffinity='--set affinity.podAntiAffinity=""'
fi
helm install eric-data-object-storage-mn $helm_rel --namespace=$ns --set drivesPerNode=$drives $local_secret --set replicas=$replica $memsetres $cpusetres $memsetlimit $cpusetlimit --set autoEncryption.enabled=false --set global.security.tls.enabled=false --set persistentVolumeClaim.size=60Gi $affinity $antiaffinity
sleep 60

echo "Helm installed ObjectStore .. waiting to come up...">>$result_file 
statusAll="NotRunning"
while [ $statusAll != "Running" ];do
sleep 30
statusAll="Running"
for ((i=0;i<=replicas-1;i++)); do
status=$(kubectl get -o template pod/eric-data-object-storage-mn-$i --template={{.status.phase}} -n $ns)
if [ $status != "Running" ];then
statusAll="NotRunning"
fi
done
done
echo "All MN servers are  running..."
echo "############################################################" >> $result_file
echo "#########     Distributed:TLS=OFF                 ###########" >> $result_file
echo "############################################################" >> $result_file
}
clearnodes() {

# remove the allpodstogether label from all nodes
echo "removing allpodstogether label from all nodes .." >> $result_file
for node in `kubectl get nodes |grep worker|awk '{print $1}'`;do
kubectl label node $node allpodstogether- >/dev/null 2>&1;
done
}
create_testpod() {
# Test POD
helm uninstall test-obj-store -n $ns >/dev/null 2>&1
sleep 60 
# remove the allpodstogether label from all nodes
clearnodes
if [ $1 == "same" ];then
node=$selectednode
kubectl label nodes $node allpodstogether=sure
fi
# what node is mn-0 on?
if [ $2 == "tls-on" ];then
local_secret="--set tls.enabled=true --set credentials.kubernetesSecretName=eric-eo-object-store-cred"
else
local_secret="--set tls.enabled=false"
fi

if [ $1 == "same" ];then
echo "##################################################################" >> $result_file
echo "########    Creating test with PODS on same NODE    ##################" >> $result_file
echo "#####################################################################" >> $result_file
cp $basedir/test-obj-store/deployment-same.yaml $basedir/test-obj-store/templates/deployment.yaml
else
echo " "
echo "#######################################################################" >> $result_file
echo "########    Creating test with PODS on different NODE    ################" >> $result_file
echo "#######################################################################" >> $result_file
cp $basedir/test-obj-store/deployment-notsame.yaml $basedir/test-obj-store/templates/deployment.yaml
fi
echo "local secret is $local_secret"
helm install --debug test-obj-store $basedir/test-obj-store/ -n $ns $local_secret

sleep 60
testpod=$(kubectl get po -n $ns|grep test-obj-store|awk '{print $1}')
echo "test pod is $testpod"
status=$(kubectl get -o template pod/$testpod --template={{.status.phase}} -n $ns)
echo "Status of $testpod POD is " $status
while [ $status != "Running" ];do
echo "$testpod not running yet..."
status=$(kubectl get -o template pod/$testpod --template={{.status.phase}} -n $ns)
echo "Status of $testpod is " $status
sleep 60
done
echo "$testpod is running check nodes" >> $result_file
kubectl get pod eric-data-object-storage-mn-0 -o wide --no-headers -n $ns >> $result_file
kubectl get pod $testpod -o wide --no-headers -n $ns >> $result_file

}
run_dd_script() {
$basedir/dd_test2.sh $result_file
}
run_tests() {
size=$1
basictcpfile=$2
tls_setting=$3
\rm -rf $servertmp >/dev/null 2>&1
sdkpython="file-uploader.py"
   
# update the test scripts according to parallel,part_size options
# part size is MB * 1024 *1024
partsize=$(echo $part*"1048576"|bc)
kubectl exec pod/$testpod -n $ns -c eosc -- bash -c "sed -e 's/part_size=0/part_size=$partsize/; s/num_parallel_uploads=3/num_parallel_uploads=$parallel/' /testSDK/$sdkpython >/testSDK/$sdkpython"tmp""
kubectl exec pod/$testpod -n $ns -c eosc -- bash -c "mv /testSDK/$sdkpython'tmp' /testSDK/$sdkpython"
echo "size is  $size">>$result_file
#kubectl exec pod/$testpod -n $ns -c eosc -- bash -c "head -c $size"MB" /dev/urandom >/fileToUpload.txt"
# create test file
# copy file
create_test_file $size
kubectl cp $testfile $ns/$testpod:/fileToUpload.txt -c eosc
# take measurements over time
echo "size of fileToUpload .." >>$result_file
echo "on node..">>$result_file
ls -lthr $testfile >>$result_file
echo "in pod" >>$result_file
#kubectl exec -it po/$testpod -c eosc -n $ns -- ls -lh /fileToUpload.txt >>$result_file
# SDK testing
tcpfile="SDK_python"$basictcpfile
echo "#### Start SDKpython Test session  #####:" >> $result_file
for i in {1..3}; do
sleep 5 
echo "GET YOU TRACES IN ORDER AND PRESS ENTER"
read a
echo "SDK python test $i" >> $result_file
 if [ $debug == "yes" ];then
   tracetime=30
# setup test POD tcpdump trace
   $basedir/get_traces2.sh $testpod "eosc" $ns
   kubectl exec pod/$testpod -n $ns -c tcpdump -- sh -c "tcpdump --buffer-size=6144 -s 0 -G $tracetime -W 1 -w /tmp/$testpod.pcap" &
# setup tests on the servers
   for ((i=0;i<=$replicas-1;i++)); do
   $basedir/get_traces2.sh eric-data-object-storage-mn-$i "eric-data-object-storage-mn" $ns
   done
# setup mgt server tracings may be good for bur
   mgtpod=$(kubectl get po -n $ns|grep eric-data-object-storage-mn-mgt|awk '{print $1}')
   $basedir/get_traces2.sh $mgtpod "manager" $ns
# setup traces using mc
   mgt_trace_setup
 fi
kubectl exec pod/$testpod -n $ns -c eosc -- bash -c "python /testSDK/create-bucker.py" >/dev/null 2>&1
kubectl exec pod/$testpod -n $ns -c eosc -- bash -c "python /testSDK/file-remove.py" >/dev/null 2>&1
sleep 5
echo "#### Start Test $i now   #####:" >> $result_file
start=`date +%s.%N`
kubectl exec pod/$testpod -n $ns -c eosc -- bash -c "python /testSDK/$sdkpython" >/dev/null 2>&1
end=`date +%s.%N`
runtime=$( echo "$end - $start" | bc -l )
current_throughput=$(echo "scale=2;$size/$runtime"|bc -l)
current_time=$current_throughput
echo "Throughput for file size $size is $current_time" >> $result_file
echo "Throughput for file size $size is $current_time" 
#current_time=$(time (kubectl exec pod/$testpod -n $ns -c eosc -- bash -c "python3 /testSDK/$sdkpython" >/dev/null 2>&1) 2>&1)
# convert to MB/s
#command=$(kubectl exec pod/$testpod -n $ns -c eosc -- bash -c "python3 /testSDK/$sdkpython")
 if [ $debug == "yes" ];then
# collect tracings
  \rm -rf $servertmp >/dev/null 2>&1
  mkdir $servertmp
# wait for 30 more secs to ensure that the server and mgt tcpdumps are complete
  sleep 30
  workerip=$(kubectl get pod/$testpod -n $ns -o json|grep '\"hostIP'|awk -F ':' '{print $2}'|awk -F ',' '{print $1}'|awk -F '"' '{print $2}')
  scp $workerip:~/$testpod.pcap $servertmp
  ssh $workerip "rm ~/$testpod.pcap"
#  kubectl cp $ns/$testpod:/tmp/$testpod.pcap -c eosc $servertmp/$testpod.pcap
#kubectl rm $ns/$testpod:/tmp/$testpod.pcap -c eosc $servertmp/$testpod.pcap
# testpod
#  pid=$(kubectl exec pod/$testpod -n $ns -c tcpdump -- sh -c "ps -ef|grep 'tcpdump --buffer-size'|egrep -v 'sh|grep'"|awk '{print $1}')
#  kubectl exec pod/$testpod -n $ns -c tcpdump -- sh -c "kill -9 $pid"
  #workerip=$(kubectl get pod/$testpod -n $ns -o json|grep '\"hostIP'|awk -F ':' '{print $2}'|awk -F ',' '{print $1}'|awk -F '"' '{print $2}')
  #scp $workerip:~/$testpod.pcap $servertmp
  #ssh $workerip "rm ~/$testpod.pcap"
  for ((i=0;i<=$replicas-1;i++)); do
  workerip=$(kubectl get pod/eric-data-object-storage-mn-$i -n $ns -o json|grep '\"hostIP'|awk -F ':' '{print $2}'|awk -F ',' '{print $1}'|awk -F '"' '{print $2}')
  scp $workerip:~/eric-data-object-storage-mn-$i.pcap $servertmp
  ssh $workerip "rm ~/eric-data-object-storage-mn-$i.pcap"
  done
# get mgt tcpump
  workerip=$(kubectl get pod/$mgtpod -n $ns -o json|grep '\"hostIP'|awk -F ':' '{print $2}'|awk -F ',' '{print $1}'|awk -F '"' '{print $2}')
  scp $workerip:~/$mgtpod.pcap $servertmp
  ssh $workerip "rm ~/$mgtpod.pcap"
####
  mgt_trace_copy_cleanup
  fi
update_min_max
touch $testdir/$current_time"mbs__"$tcpfile

kubectl exec pod/$testpod -n $ns -c tcpdump -- sh -c "rm /$tcpfile" >/dev/null 2>&1
# only keep the min and max values 
if [ $i == 1 ];then
max_time=$current_time
min_time=$current_time
fi

number=$(ls $testdir/*$tcpfile | wc -l)
if [ $number -eq 2 ] && [ "$current_time" \< "$min_time" ];then
min_time=$current_time
elif [ $number -eq 2 ] && [ "$current_time" \> "$max_time" ];then
max_time=$current_time
fi

echo "min time is $min_time"
echo "max time is $max_time"
echo "number is $number"
if [ $number -gt 2 ] && [ "$current_time" \< "$min_time" ];then
 rm $testdir/$min_time"mbs__"$tcpfile
 min_time=$current_time
elif [ $number -gt 2 ] && [ "$current_time" \> "$max_time" ];then
 rm $testdir/$max_time"mbs__"$tcpfile
 max_time=$current_time
elif [ $number -gt 2 ]; then
# remove this tcpdump file as not a max or min
 rm $testdir/$current_time"mbs__"$tcpfile
fi
echo "Min time is now $min_time"
echo "Max time is now $max_time"

# only above is for 200MB files
###############fi
done
}

set_kernel_default() {
# Also remove the allpodstogether label from al the nodes
# remove allpodstogether label put at start of script
for node in `kubectl get nodes |grep worker|awk '{print $1}'`;do
kubectl label node $node allpodstogether- >/dev/null 2>&1;
done
}
set_kernel_tcp() {
for node in `kubectl get nodes -o wide|grep worker|awk '{print $6}'`;do
ssh $node sudo sysctl net.core.rmem_max=268435456
ssh $node sudo sysctl net.core.wmem_max=268435456
ssh $node sudo sysctl net.core.rmem_default=67108864
ssh $node sudo sysctl net.core.wmem_default=67108864
ssh $node sudo sysctl net.ipv4.tcp_rmem=\'67108864 134217728 268435456\'
ssh $node sudo sysctl net.ipv4.tcp_wmem=\'67108864 134217728 268435456\'
sleep 2
done
lastnode=$node
# Also remove the allpodstogether label from al the nodes
# remove allpodstogether label put at start of script
for node in `kubectl get nodes |grep worker|awk '{print $1}'`;do
kubectl label node $node allpodstogether- >/dev/null 2>&1;
done

}

print_kernel() {
echo "Confirming kernel params::">>$result_file
ssh $lastnode sudo sysctl net.core.rmem_max net.core.wmem_max net.core.rmem_default net.core.wmem_default net.ipv4.tcp_rmem net.ipv4.tcp_wmem >>$result_file
}

test_all_standalone() {
if [ "$1" == "tls-on"  ]; then
 create_mn_standalone
 create_testpod $nodes $ssl
 run_tests $size "ver_"$rel"_Standalone_"$size"mb_"$nodes"_Nodes_"$currtcp"_tlsON""_mem:"$memres","$memlimits"_cpu:"$cpures","$cpulimits"_par"$parallel"_partsize"$part "tls-on"
else
# command line specifies same or notsame only
create_mn_standalone_tlsoff $nodes
#run_dd_script
create_testpod $nodes $ssl
 for size in $sizes;do 
  run_tests $size "ver_"$rel"_Standalone_"$size"mb_"$nodes"_Nodes_"$currtcp"_tlsOFF""_mem:"$memres","$memlimits"_cpu:"$cpures","$cpulimits"_par"$parallel"_partsize"$part "tls-off"
 done
fi
}

setup_tcp() {
# return 1 for now
return 1
if [ "$1" == "def" ]; then
currtcp="defTCP"
echo "#########################################################" >>$result_file
echo "##########  Setup Kernel Default  ############" >>$result_file
echo "##########################################################" >>$result_file
set_kernel_default
print_kernel
else
currtcp="chgTCP"
echo "##############################################################" >>$result_file
echo "##########  Setup Kernel TCP Changed  ############" >>$result_file
echo "##############################################################" >>$result_file
set_kernel_tcp
print_kernel
fi
}
test_all_distributed() {
# cleanup later
if [ $1 == "tls-on" ];then
local_secret="--set tls.enabled=true --set credentials.kubernetesSecretName=eric-eo-object-store-cred"
else
local_secret="--set tls.enabled=false --set credentials.kubernetesSecretName=eric-eo-object-store-cred"
fi

#tls-off
if [ $existing_depl == "no" ]; then
  for nodes in $nodeslist;do
  for replica in $replicas;do
  for drives in $drivespernode;do
    create_mn_distributed $1 $nodes
    create_testpod $nodes $ssl
      for parallel in $parallellist;do
        for part in $multiparts;do
          for size in $sizes;do
            run_tests $size "ver_"$rel"_Dist_"$size"mb_""Replicas_"$replica"_drives_"$drives"_"$nodes"_Nodes_"$currtcp"_mem:"$memres","$memlimits"_cpu:_"$cpures","$cpulimits"_par"$parallel"_partsize"$part""$1 $1
          done
        done
      done
  done
  done
  done
else
  create_testpod $nodes $ssl
      for parallel in $parallellist;do
        for part in $multiparts;do
          for size in $sizes;do
            run_tests $size "ver_"$rel"_Dist_"$size"mb_""Replicas_"$replica"_drives_"$drives"_"$nodes"_Nodes_"$currtcp"_mem:"$memres","$memlimits"_cpu:_"$cpures","$cpulimits"_par"$parallel"_partsize"$part""$1 $1
          done
        done
      done
fi







}
#basedir=`dirname "$0"`
basedir="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
resultsdir=$basedir
configuration="dist"
tcp="def"
currtcp="defTCP"
ssl="tls-off"
nodeslist="notsame"
parallellist="3"
part="0"
debug="no"
# default is to test in an empty namespace, create ObjectStore and testpod
sizes="1 10 100 200 1000 2000 5000 10000 20000"
multiparts="5"
drivespernode="1" 
replicas=4
existing_depl="no"
latest_object_store_rel="1.23.0+22"
#sizes="1 10 100 200 1000"
#sizes="1 10 100 200" 
while getopts t:c:s:n:m:p:b:a:l:d:f:e:r:t:u:v:k:x:g:h: flag
do
    case "${flag}" in
        c) configuration="${OPTARG}";;
        t) tcp="${OPTARG}";;
        s) ssl="${OPTARG}";;
        n) nodeslist="${OPTARG}";;
        m) memlimits="${OPTARG}";; 
        p) cpulimits="${OPTARG}";; 
        u) memres="${OPTARG}";; 
        v) cpures="${OPTARG}";; 
        b) resultsdir="${OPTARG}";; 
        a) parallellist="${OPTARG}";; 
        l) multiparts="${OPTARG}";; 
        d) debug="${OPTARG}";; 
        f) sizes="${OPTARG}";; 
        k) selectednode="${OPTARG}";; 
        e) ns="${OPTARG}";; 
        r) rel="${OPTARG}";; 
        x) existing_depl="${OPTARG}";; 
        g) drivespernode="${OPTARG}";; 
        h) replicas="${OPTARG}";; 
        *) usage
           exit 0;;
    esac
done
if [ $existing_depl == "yes" ]; then
 if [ -z $ns ];then
  echo "Existing depl selected, but no namepace selected"
  echo "Need a -e parameter set"
  exit 1
 fi
 kubectl get namespace $ns >/dev/null 2>&1
 nsok=$?
 if [ $nsok != 0 ];then
  echo "Namespace specified does not exist"
  exit 1
 fi
# check the tls setting matches whats already running
mgtpod=$(kubectl get po -n $ns|grep eric-data-object-storage-mn-mgt|awk '{print $1}')
existingtls=$(kubectl exec pod/$mgtpod -c manager -n $ns -- printenv TLS_ENABLED)
# for existing ns overwrite tls setting (if needed)
  if [ $existingtls == "true" ];then
   ssl="tls-on"
  else
   ssl="tls-off"
  fi
fi


if [ -z $ns ];then
echo "Using storobj-test as a 'testing' namespace"
ns="storobj-test"
kubectl delete namespace $ns >/dev/null 2>&1
kubectl create namespace $ns >/dev/null 2>&1
# create secrets for Objectstore accesskey,secretkey
kubectl apply -f $basedir/test-obj-store/eric-eo-object-store-cred.yaml -n $ns
fi

if [ -z $rel ];then
rel=$latest_object_store_rel
fi
helm_rel="https://arm.sero.gic.ericsson.se/artifactory/proj-adp-eric-data-object-storage-mn-released-helm/eric-data-object-storage-mn/eric-data-object-storage-mn-"$rel".tgz"
if [ ! -z $memlimits ];then
#   not taking the defaults
 memsetlimit="--set server.resources.limits.memory=$memlimits"
else
 memsetlimit=""
 memlimits="def_mem_lim"
fi
if [ ! -z $cpulimits ];then
 cpusetlimit="--set server.resources.limits.cpu=$cpulimits"
else
 cpusetlimit=""
 cpulimits="def_cpu_lim"
fi

if [ ! -z $memres ];then
#   not taking the defaults
 memsetres="--set server.resources.requests.memory=$memres"
else
 memsetres=""
 memres="def_mem_res"
fi
if [ ! -z $cpures ];then
 cpusetres="--set server.resources.requests.cpu=$cpures"
else
 cpusetres=""
 cpures="def_cpu_res"
fi

allparams=$configuration"_""_Rel_"$rel"_tcp_"$tcp"_"$ssl"_mem:"$memres","$memlimits"_cpu:"$cpures","$cpulimits"_parall"$parallellist"_partsize"$part"_"
# Start
TIMEFORMAT=%R
testtime=$(date +"%m_%d_%Y_%H_%M")
testdir=$resultsdir"/results/"$allparams$testtime
mindir=$resultsdir"/results/MIN"
maxdir=$resultsdir"/results/MAX"
servertmp=$resultsdir"/results/Servertmptcpdumps"
mkdir -p $servertmp
mkdir -p $testdir
mkdir -p $mindir
mkdir -p $maxdir
result_file=$testdir/Test_Run
echo "-------------START---------------------">$result_file
date >>$result_file
echo "Parameters:">>$result_file
echo "Configuration (-c sa/dist) :  $configuration">>$result_file
echo "SSL  (-s tls-on/tls-off) :  $ssl">>$result_file
echo "TCP (-t def/chg ) :  $tcp">>$result_file
echo "CPU  :  $cpulimits">>$result_file
echo "MEM  : $memlimits">>$result_file
echo "Parallel (-a ): $parallel">>$result_file
echo "Part Size (-l  ) : $part">>$result_file
echo "Release (-r  ) : $helm_rel">>$result_file


if [ "$tcp" = "def" ];then
# run all the tests using default TCP only
setup_tcp "def"
# now check what configurations to run
 if [ "$configuration" = "sa" ];then
    test_all_standalone $ssl
 elif [ "$configuration" = "dist" ]; then
    test_all_distributed $ssl
 else
    test_all_distributed $ssl
    test_all_standalone $ssl
 fi
# if using changed TCP settings
elif [ "$tcp" = "chg" ]; then
setup_tcp "chg"
# now check what configurations to run
 if [ "$configuration" = "sa" ];then
    test_all_standalone $ssl
 elif [ "$configuration" = "dist" ]; then
    test_all_distributed $ssl
 else
    test_all_distributed $ssl
    test_all_standalone $ssl
 fi
# if no preference then run both
else
 if [ "$configuration" = "sa" ];then
    setup_tcp "def"
    test_all_standalone $ssl
    setup_tcp "chg"
    test_all_standalone $ssl
 elif [ "$configuration" = "dist" ]; then
    setup_tcp "def"
    test_all_distributed $ssl
    setup_tcp "chg"
    test_all_distributed $ssl
 else
    setup_tcp "def"
    test_all_distributed $ssl
    test_all_standalone $ssl
    setup_tcp "chg"
    test_all_distributed $ssl
    test_all_standalone $ssl
 fi
fi
