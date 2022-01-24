#!/bin/bash
usage() {
echo "Usage .. "
echo "-s 'tls-on/tls-off' (TLS on or off)"
echo "-c 'dist/sa' (Configuration is Distributed or Standalone"
echo "-t 'def/chg' (TCP settings as Default or Changed"
echo "-n 'diff' (Only test Standalone using different nodes)"
echo "-m '5120Mi' (example memory size limits of POD)"
echo "-p '4000m' (exeample CPU size limits of POD)"
echo "-a '3' (number of parallel TCP sessions (default 3))"
echo "-l '200' (example 200MB part size (default is 5MB)"
echo "-d 'yes' (create debug logs )"
echo "-f '200' (size of file (MB) to create )"
}
mgt_trace_setup() {
kubectl exec pod/$mgtpod -n storobj-test  -- bash -c "mc config --insecure host add myminio http://eric-data-object-storage-mn:9000 AKIAIOSFODNN7EXAMPLE wJalrXUtnFEMIK7MDENGbPxRfiCYEXAMPLEKEY"
kubectl exec pod/$mgtpod -n storobj-test  -- bash -c "rm -rf /tmp/my-serverconfig"
kubectl exec pod/$mgtpod -n storobj-test  -- bash -c "rm -rf /tmp/lock_info"
kubectl exec pod/$mgtpod -n storobj-test  -- bash -c "rm -rf /tmp/tracefile"
kubectl exec pod/$mgtpod -n storobj-test  -- bash -c "mc admin config export myminio > /tmp/my-serverconfig"
kubectl exec pod/$mgtpod -n storobj-test  -- bash -c "mc admin top locks myminio >/tmp/lock_info"
kubectl exec pod/$mgtpod -n storobj-test  -- bash -c "cd ~; mc admin profile start myminio/"
kubectl exec pod/$mgtpod -n storobj-test  -- bash -c "mc admin --insecure --debug trace -v -all myminio >/tmp/tracefile" &
kubectl exec pod/$mgtpod -n storobj-test  -- bash -c "cd ~;mc admin profile stop myminio/"
}

mgt_trace_copy_cleanup() {
pid=$(kubectl exec pod/$mgtpod -n storobj-test -- bash -c "ps -ef|grep tracefile|egrep -v 'grep'"|awk '{print $2}')
kubectl exec pod/$mgtpod -n storobj-test -- bash -c "kill -9 $pid"
pid=$(kubectl exec pod/$mgtpod -n storobj-test -- bash -c "ps -ef|grep 'mc admin --insecure --debug trace -v -all myminio'|egrep -v 'grep'"|awk '{print $2}')
kubectl exec pod/$mgtpod -n storobj-test -- bash -c "kill -9 $pid"


kubectl cp storobj-test/$mgtpod:/tmp/my-serverconfig $servertmp/my-serverconfig
kubectl cp storobj-test/$mgtpod:/tmp/lock_info $servertmp/lock_info
kubectl cp storobj-test/$mgtpod:/tmp/tracefile $servertmp/tracefile
kubectl cp storobj-test/$mgtpod:/minio/profile.zip $servertmp/profile.zip
}
create_test_file() {

testfile="$basedir/fileToUpload.txt"
result=$(( 3000 * $size ))
rm $testfile >/dev/null 2>&1
for ((i = 0 ; i <= $result ; i++)); do
echo "###########################################################################################################">>$testfile
echo "###################################### line $i ########################################################################">>$testfile
echo "####################################################################################################################">>$testfile
done
}



update_min_max() {
# check the current MB/s value, and compare with the MIN and MAX values obtained for this test case
# If a new MIN or MAX, then overwrite the previous (tcpdump) file

ls $mindir/*$tcpfile >/dev/null 2>&1
fileexists=$?
if [ $fileexists == 0 ];then
 echo "file exists"
# compare the current mbs with mbs from MIN dir
 cd $mindir
 mbsmin=$(ls *$tcpfile|awk -F 'mbs' '{print $1}')
 if (( $(echo "$current_time < $mbsmin"|bc -l) )); then
  rm *$tcpfile
  \rm -rf $mindir/*$tcpfile"Server_traces" >/dev/null 2>&1 
   if [ $debug == "yes" ];then
    kubectl cp storobj-test/$testpod:/$tcpfile $mindir/$current_time"mbs__"$tcpfile -c tcpdump
    mkdir $mindir/$current_time"mbs__"$tcpfile"Server_traces" >/dev/null 2>&1 
 # copy server tcpdumps
    cp $servertmp/* $mindir/$current_time"mbs__"$tcpfile"Server_traces" 
   else
    touch $mindir/$current_time"mbs__"$tcpfile
   fi

   echo "**** NEW MIN of $current_time mbs for test $tcpfile">>$result_file
  fi
else
echo "file NOT exists"
# so just copy this current to be the min value now

 if [ $debug == "yes" ]; then
  kubectl cp storobj-test/$testpod:/$tcpfile $mindir/$current_time"mbs__"$tcpfile -c tcpdump
  mkdir $mindir/$current_time"mbs__"$tcpfile"Server_traces" >/dev/null 2>&1
# copy server tcpdumps
  cp $servertmp/* $mindir/$current_time"mbs__"$tcpfile"Server_traces"
 else
  touch $mindir/$current_time"mbs__"$tcpfile
 fi
# record this timing
fi
# check against MAX values
ls $maxdir/*$tcpfile >/dev/null 2>&1
fileexists=$?
if [ $fileexists == 0 ];then
 echo "file exists"
# compare the current mbs with mbs from MAx dir
 cd $maxdir
 mbsmax=$(ls *$tcpfile|awk -F 'mbs' '{print $1}')
 if (( $(echo "$current_time > $mbsmax"|bc -l) )); then
  rm *$tcpfile
  \rm -rf $maxdir/*$tcpfile"Server_traces" >/dev/null 2>&1 

  if [ $debug == "yes" ];then
   kubectl cp storobj-test/$testpod:/$tcpfile $maxdir/$current_time"mbs__"$tcpfile -c tcpdump
   mkdir $maxdir/$current_time"mbs__"$tcpfile"Server_traces" >/dev/null 2>&1 
   cp $servertmp/* $maxdir/$current_time"mbs__"$tcpfile"Server_traces" 
  else
    touch $maxdir/$current_time"mbs__"$tcpfile
  fi

 echo "**** NEW MAX of $current_time mbs for test $tcpfile">>$result_file
 fi
else
echo "file NOT exists"
# so copy this current to be the max value now
 if [ $debug == "yes" ]; then
  kubectl cp storobj-test/$testpod:/$tcpfile $maxdir/$current_time"mbs__"$tcpfile -c tcpdump
  mkdir $maxdir/$current_time"mbs__"$tcpfile"Server_traces" >/dev/null 2>&1
# copy server tcpdumps
  cp $servertmp/* $maxdir/$current_time"mbs__"$tcpfile"Server_traces"
 else
  touch $maxdir/$current_time"mbs__"$tcpfile
 fi
fi
}
create_mn_standalone() {
replicas=1
helm uninstall eric-data-object-storage-mn -n storobj-test
sleep 60
kubectl delete pvc export-eric-data-object-storage-mn-0 -n storobj-test
kubectl delete pvc export-eric-data-object-storage-mn-1 -n storobj-test
kubectl delete pvc export-eric-data-object-storage-mn-2 -n storobj-test
kubectl delete pvc export-eric-data-object-storage-mn-3 -n storobj-test
sleep 60
helm install eric-data-object-storage-mn https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-eric-data-object-storage-mn-released-helm/eric-data-object-storage-mn/eric-data-object-storage-mn-1.11.0+19.tgz -f $basedir/test-obj-store/mn-values.yaml --namespace=storobj-test --set mode=standalone --set replicas=1 --set credentials.kubernetesSecretName=test-secret --set autoEncryption.enabled=true --set global.security.tls.enabled=true --set persistentVolumeClaim.size=40Gi
sleep 60
status=$(kubectl get -o template pod/eric-data-object-storage-mn-0 --template={{.status.phase}} -n storobj-test)
echo "Status of MN-0 POD is " $status
echo "Status of MN-0 POD is " $status
while [ $status != "Running" ];do
echo "MN-0 not running yet..."
status=$(kubectl get -o template pod/eric-data-object-storage-mn-0 --template={{.status.phase}} -n storobj-test)
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
helm uninstall eric-data-object-storage-mn -n storobj-test
sleep 20
kubectl delete pvc export-eric-data-object-storage-mn-0 -n storobj-test
kubectl delete pvc export-eric-data-object-storage-mn-1 -n storobj-test
kubectl delete pvc export-eric-data-object-storage-mn-2 -n storobj-test
kubectl delete pvc export-eric-data-object-storage-mn-3 -n storobj-test
sleep 60
helm install eric-data-object-storage-mn https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-eric-data-object-storage-mn-released-helm/eric-data-object-storage-mn/eric-data-object-storage-mn-1.11.0+19.tgz -f $basedir/test-obj-store/mn-values.yaml --namespace=storobj-test --set mode=standalone --set replicas=1 --set credentials.kubernetesSecretName=test-secret --set autoEncryption.enabled=false --set global.security.tls.enabled=false --set persistentVolumeClaim.size=40Gi
sleep 60
# initial status
#sleep 300
sleep 60
status=$(kubectl get -o template pod/eric-data-object-storage-mn-0 --template={{.status.phase}} -n storobj-test)
echo "Status of MN-0 POD is " $status
while [ $status != "Running" ];do
echo "MN-0 not running yet..."
status=$(kubectl get -o template pod/eric-data-object-storage-mn-0 --template={{.status.phase}} -n storobj-test)
echo "Status of MN-0 is " $status
sleep 60
done
echo "Mn-0 is running"
echo "###########################################################" >> $result_file
echo "################      Standalone:::TLS=OFF             ###########" >> $result_file
echo "###########################################################" >> $result_file
}

create_mn_distributed() {
replicas=4
helm uninstall eric-data-object-storage-mn -n storobj-test
for ((i=0;i<=$replicas-1;i++)); do
kubectl delete pvc export-eric-data-object-storage-mn-$i -n storobj-test
done
sleep 120
helm install eric-data-object-storage-mn https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-eric-data-object-storage-mn-released-helm/eric-data-object-storage-mn/eric-data-object-storage-mn-1.11.0+19.tgz --namespace=storobj-test --set credentials.kubernetesSecretName=test-secret --set replicas=$replicas --set server.resources.limits.memory=$memlimits --set server.resources.limits.cpu=$cpulimits --set server.resources.requests.memory=512Mi --set server.resources.requests.cpu=100m --set autoEncryption.enabled=true --set global.security.tls.enabled=true --set persistentVolumeClaim.size=40Gi
# initial status
#sleep 300
sleep 60

statusAll="NotRunning"
while [ $statusAll != "Running" ];do
sleep 30
statusAll="Running"
for ((i=0;i<=$replicas-1;i++)); do
status=$(kubectl get -o template pod/eric-data-object-storage-mn-$i --template={{.status.phase}} -n storobj-test)
if [ $status != "Running" ];then
statusAll="NotRunning"
fi
done
done
echo "All MN servers are  running..."
echo "############################################################" >> $result_file
echo "#########     Distributed:TLS=ON                 ###########" >> $result_file
echo "############################################################" >> $result_file
}



create_mn_distributed_tlsoff() {
#replicas=$1
replicas=4
helm uninstall eric-data-object-storage-mn -n storobj-test
for ((i=0;i<=replicas-1;i++)); do
kubectl delete pvc export-eric-data-object-storage-mn-$i -n storobj-test
done
sleep 120
helm install eric-data-object-storage-mn https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-eric-data-object-storage-mn-released-helm/eric-data-object-storage-mn/eric-data-object-storage-mn-1.11.0+19.tgz --namespace=storobj-test --set credentials.kubernetesSecretName=test-secret --set replicas=$replicas --set server.resources.limits.memory=5120Mi --set server.resources.limits.cpu=4000m --set server.resources.requests.memory=512Mi --set server.resources.requests.cpu=100m --set autoEncryption.enabled=false --set global.security.tls.enabled=false --set persistentVolumeClaim.size=40Gi
# initial status
#sleep 300
sleep 60

statusAll="NotRunning"
while [ $statusAll != "Running" ];do
sleep 30
statusAll="Running"
for ((i=0;i<=replicas-1;i++)); do
status=$(kubectl get -o template pod/eric-data-object-storage-mn-$i --template={{.status.phase}} -n storobj-test)
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
create_testpod() {
# Test POD
helm uninstall test-obj-store -n storobj-test
sleep 120
# remove the allpodstogether label from all nodes
echo "removing allpodstogether label from all nodes .." >> $result_file
for node in `kubectl get nodes |grep worker|awk '{print $1}'`;do
kubectl label node $node allpodstogether- >/dev/null 2>&1;
done
# what node is mn-0 on?
if [ $1 == "same" ];then
echo "##################################################################" >> $result_file
echo "########    Creating test with PODS on same NODE    ##################" >> $result_file
echo "#####################################################################" >> $result_file
node=`kubectl get pod eric-data-object-storage-mn-0 -o wide --no-headers -n storobj-test|awk '{print $7}'`
kubectl label nodes $node allpodstogether=sure
cp $basedir/test-obj-store/deployment-same.yaml $basedir/test-obj-store/templates/deployment.yaml
helm install test-obj-store $basedir/test-obj-store/ -n storobj-test
else
echo " "
echo "#######################################################################" >> $result_file
echo "########    Creating test with PODS on different NODE    ################" >> $result_file
echo "#######################################################################" >> $result_file
cp $basedir/test-obj-store/deployment-notsame.yaml $basedir/test-obj-store/templates/deployment.yaml
helm install test-obj-store $basedir/test-obj-store/ -n storobj-test
fi
sleep 60
testpod=$(kubectl get po -n storobj-test|grep test-obj-store|awk '{print $1}')
echo "test pod is $testpod"
status=$(kubectl get -o template pod/$testpod --template={{.status.phase}} -n storobj-test)
echo "Status of $testpod POD is " $status
while [ $status != "Running" ];do
echo "$testpod not running yet..."
status=$(kubectl get -o template pod/$testpod --template={{.status.phase}} -n storobj-test)
echo "Status of $testpod is " $status
sleep 60
done
echo "$testpod is running check nodes" >> $result_file
kubectl get pod eric-data-object-storage-mn-0 -o wide --no-headers -n storobj-test >> $result_file
kubectl get pod $testpod -o wide --no-headers -n storobj-test >> $result_file

}
run_tests() {
size=$1
basictcpfile=$2
tls_setting=$3
\rm -rf $servertmp >/dev/null 2>&1
if [ "$tls_setting" == "tls-on" ];then
 echo "Running tests for TLS=on mode" >>$result_file
 benchhttp="https"
 sdkpython="file-uploader.py"
else
 echo "Running tests for TLS=off mode" >>$result_file
 benchhttp="http"
 sdkpython="file-uploader_tlsoff.py"
fi
   
# update the test scripts according to parallel,part_size options
# part size is MB * 1024 *1024
partsize=$(echo $part*"1048576"|bc)
kubectl exec pod/$testpod -n storobj-test -c eosc -- bash -c "sed -e 's/part_size=0/part_size=$partsize/; s/num_parallel_uploads=3/num_parallel_uploads=$parallel/' /testSDK/$sdkpython >/testSDK/$sdkpython"tmp""
kubectl exec pod/$testpod -n storobj-test -c eosc -- bash -c "mv /testSDK/$sdkpython'tmp' /testSDK/$sdkpython"
echo "size is  $size">>$result_file
#kubectl exec pod/$testpod -n storobj-test -c eosc -- bash -c "head -c $size"MB" /dev/urandom >/fileToUpload.txt"
# create test file
# copy file
create_test_file $size
kubectl cp $testfile storobj-test/$testpod:/fileToUpload.txt -c eosc
# take measurements over time

# SDK testing
tcpfile="SDK_python"$basictcpfile
echo "#### Start SDKpython Test session  #####:" >> $result_file
for i in {1..2}; do
#sleep 5 
echo "SDK python test $i" >> $result_file
if [ $ssl == "tls-off" ];then
 if [ $debug == "yes" ];then

 kubectl exec pod/$testpod -n storobj-test -c tcpdump -- sh -c "tcpdump --buffer-size=6144 -s 0 -w /$tcpfile &"

# setup tests on the servers and mgt pod
 for ((i=0;i<=$replicas-1;i++)); do
 $basedir/get_traces2.sh eric-data-object-storage-mn-$i
 done
 mgtpod=$(kubectl get po -n storobj-test|grep eric-data-object-storage-mn-mgt|awk '{print $1}')
 $basedir/get_traces2.sh $mgtpod
# get the tracefiles created on mgt pod
 mgt_trace_setup
 fi
current_time=$(time (kubectl exec pod/$testpod -n storobj-test -c eosc -- bash -c "python3 /testSDK/$sdkpython" >/dev/null 2>&1) 2>&1)
# convert to MB/s
current_time=$(echo "scale=2;$size/$current_time"|bc -l)
echo "Throughput is $current_time"
echo "Throughput is $current_time" >> $result_file
 if [ $debug == "yes" ];then
  pid=$(kubectl exec pod/$testpod -n storobj-test -c tcpdump -- sh -c "ps -ef|grep 'tcpdump --buffer-size'|egrep -v 'sh|grep'"|awk '{print $1}')
  kubectl exec pod/$testpod -n storobj-test -c tcpdump -- sh -c "kill -9 $pid"

# wait for 30 secs to ensure that the server and mgt tcpdumps are complete
  sleep 30
# get tcpdump for mn and mgt pods
  \rm -rf $servertmp >/dev/null 2>&1
  mkdir $servertmp
  for ((i=0;i<=$replicas-1;i++)); do
  workerip=$(kubectl get pod/eric-data-object-storage-mn-$i -n storobj-test -o json|grep '\"hostIP'|awk -F ':' '{print $2}'|awk -F ',' '{print $1}'|awk -F '"' '{print $2}')
  scp $workerip:~/eric-data-object-storage-mn-$i.pcap $servertmp
  ssh $workerip "rm ~/eric-data-object-storage-mn-$i.pcap"
  done
# get mgt tcpump
  workerip=$(kubectl get pod/$mgtpod -n storobj-test -o json|grep '\"hostIP'|awk -F ':' '{print $2}'|awk -F ',' '{print $1}'|awk -F '"' '{print $2}')
  scp $workerip:~/$mgtpod.pcap $servertmp
  ssh $workerip "rm ~/$mgtpod.pcap"
####
  mgt_trace_copy_cleanup
  fi
update_min_max
touch $testdir/$current_time"mbs__"$tcpfile

kubectl exec pod/$testpod -n storobj-test -c tcpdump -- sh -c "rm /$tcpfile" >/dev/null 2>&1
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
fi
done
echo "#### Stop Test session  #####:" >> $result_file
echo "#### Start S3-benchmark Test session  #####:" >> $result_file
# s3-benchmark testing
tcpfile="S3-bench"$basictcpfile
# S3-benchmark testing
for i in {1..2}; do
sleep 5
echo "S3 Bench python test $i" >> $result_file
if [ $ssl == "tls-off" ];then
 if [ $debug == "yes" ];then
  kubectl exec pod/$testpod -n storobj-test -c tcpdump -- sh -c "tcpdump --buffer-size=6144 -s 0 -w /$tcpfile &"
# setup tests on the servers and mgt pod
  for ((i=0;i<=$replicas-1;i++)); do
  $basedir/get_traces2.sh eric-data-object-storage-mn-$i
  done
  mgtpod=$(kubectl get po -n storobj-test|grep eric-data-object-storage-mn-mgt|awk '{print $1}')
  $basedir/get_traces2.sh $mgtpod
 fi
kubectl exec pod/$testpod -n storobj-test -c eosc -- bash -c "/s3-benchmark/s3-benchmark -t 5 -d 1 -z $sizeMB -a AKIAIOSFODNN7EXAMPLE -s wJalrXUtnFEMIK7MDENGbPxRfiCYEXAMPLEKEY -u $benchhttp://eric-data-object-storage-mn:9000" >$testdir/tstfile
current_time=$(cat $testdir/tstfile |grep PUT|grep PUT|awk '{print $12}'|sed s'/MB\/sec,'//g)
rm $testdir/tstfile
echo "Time in seconds is $current_time"
echo "Time in seconds is $current_time" >> $result_file
 if [ $debug == "yes" ];then
  pid=$(kubectl exec pod/$testpod -n storobj-test -c tcpdump -- sh -c "ps -ef|grep 'tcpdump --buffer-size'|egrep -v 'sh|grep'"|awk '{print $1}')
  kubectl exec pod/$testpod -n storobj-test -c tcpdump -- sh -c "kill -9 $pid"
# wait for 30 secs to ensure that the server and mgt tcpdumps are complete
  sleep 30
# get tcpdump for mn and mgt pods
  \rm -rf $servertmp >/dev/null 2>&1
  mkdir $servertmp
  for ((i=0;i<=$replicas-1;i++)); do
  workerip=$(kubectl get pod/eric-data-object-storage-mn-$i -n storobj-test -o json|grep '\"hostIP'|awk -F ':' '{print $2}'|awk -F ',' '{print $1}'|awk -F '"' '{print $2}')
  scp $workerip:~/eric-data-object-storage-mn-$i.pcap $servertmp
  ssh $workerip "rm ~/eric-data-object-storage-mn-$i.pcap"
  done
# get mgt tcpump
  workerip=$(kubectl get pod/$mgtpod -n storobj-test -o json|grep '\"hostIP'|awk -F ':' '{print $2}'|awk -F ',' '{print $1}'|awk -F '"' '{print $2}')
  scp $workerip:~/$mgtpod.pcap $servertmp
  ssh $workerip "rm ~/$mgtpod.pcap"
  fi
update_min_max
touch $testdir/$current_time"mbs__"$tcpfile
kubectl exec pod/$testpod -n storobj-test -c tcpdump -- sh -c "rm /$tcpfile" >/dev/null 2>&1
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
fi
done
echo "#########  Stop Test Session  ######################" >> $result_file
}

set_kernel_default() {
for node in `kubectl get nodes -o wide|grep worker|awk '{print $6}'`;do
ssh $node sudo sysctl fs.file-max=3282480
ssh $node sudo sysctl vm.swappiness=60
ssh $node sudo sysctl vm.vfs_cache_pressure=100
ssh $node sudo sysctl vm.min_free_kbytes=22946
ssh $node sudo sysctl net.core.rmem_max=212992
ssh $node sudo sysctl net.core.wmem_max=212992
ssh $node sudo sysctl net.core.rmem_default=212992
ssh $node sudo sysctl net.core.wmem_default=212992
ssh $node sudo sysctl net.core.netdev_budget=300
ssh $node sudo sysctl net.core.optmem_max=20480
ssh $node sudo sysctl net.core.somaxconn=128
ssh $node sudo sysctl net.core.netdev_max_backlog=1000
ssh $node sudo sysctl net.ipv4.tcp_rmem=\'4096 87380 6291456\'
ssh $node sudo sysctl net.ipv4.tcp_wmem=\'4096 16384 4194304\'
ssh $node sudo sysctl net.ipv4.tcp_low_latency=0
ssh $node sudo sysctl net.ipv4.tcp_adv_win_scale=1
ssh $node sudo sysctl net.ipv4.tcp_max_syn_backlog=1024
ssh $node sudo sysctl net.ipv4.tcp_max_tw_buckets=131072
ssh $node sudo sysctl net.ipv4.tcp_tw_reuse=0
ssh $node sudo sysctl net.ipv4.tcp_fin_timeout=60
ssh $node sudo sysctl net.ipv4.conf.all.send_redirects=0
ssh $node sudo sysctl net.ipv4.conf.all.accept_redirects=0
ssh $node sudo sysctl net.ipv4.conf.all.accept_source_route=0
ssh $node sudo sysctl net.ipv4.tcp_mtu_probing=2
sleep 2
done
lastnode=$node
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
 create_testpod "notsame"
 run_tests $size "Standalone_""$size""mb_Diff_Nodes_""$currtcp""_tlsON""_mem"$memlimits"_cpu"$cpulimits"_par"$parallel"_partsize"$part "tls-on"
 if [ "$nodes" == "all"  ]; then
  create_testpod "same"
  run_tests $size "Standalone_""$size""mb_Same_Nodes_""$currtcp""_tlsON""_mem"$memlimits"_cpu"$cpulimits"_par"$parallel"_partsize"$part "tls-on"
 fi
elif [ "$1" == "tls-off" ]; then
 create_mn_standalone_tlsoff
 create_testpod "notsame"
 run_tests $size "Standalone_""$size""mb_Diff_Nodes_""$currtcp""_tlsOFF""_mem"$memlimits"_cpu"$cpulimits"_par"$parallel"_partsize"$part "tls-off"
 if [ "$nodes" == "all"  ]; then
  create_testpod "same"
  run_tests $size "Standalone_""$size""mb_Same_Nodes_""$currtcp""_tlsOFF""_mem"$memlimits"_cpu"$cpulimits"_par"$parallel"_partsize"$part "tls-off"
 fi
else
# run test cases in both TLS=on and TLS=off modes
 create_mn_standalone
 create_testpod "notsame"
 run_tests $size "Standalone_""$size""mb_Diff_Nodes_""$currtcp""_tlsON""_mem"$memlimits"_cpu"$cpulimits"_par"$parallel"_partsize"$part "tls-on"
 if [ "$nodes" == "all"  ]; then
  create_testpod "same"
  run_tests $size "Standalone_""$size""mb_Same_Nodes_""$currtcp""_tlsON""_mem"$memlimits"_cpu"$cpulimits"_par"$parallel"_partsize"$part "tls-on"
 fi
# now run in tls off mode
 create_mn_standalone_tlsoff
 create_testpod "notsame"
 run_tests $size "Standalone_""$size""mb_Diff_Nodes_""$currtcp""_tlsOFF""_mem"$memlimits"_cpu"$cpulimits"_par"$parallel"_partsize"$part "tls-off"
 if [ "$nodes" == "all"  ]; then
  create_testpod "same"
  run_tests $size "Standalone_""$size""mb_Same_Nodes_""$currtcp""_tlsOFF""_mem"$memlimits"_cpu"$cpulimits"_par"$parallel"_partsize"$part "tls-off"
 fi
fi
}

setup_tcp() {
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
if [ "$1" == "tls-on"  ]; then
create_mn_distributed
create_testpod "notsame"
run_tests $size "Dist_""$size""mb_Diff_Nodes_""$currtcp""_tlsON""_mem"$memlimits"_cpu"$cpulimits"_par"$parallel"_partsize"$part "tls-on"
elif [ "$1" == "tls-off" ]; then
create_mn_distributed_tlsoff
create_testpod "notsame"
run_tests $size "Dist""$size""mb_Diff_Nodes_""$currtcp""_tlsOFF""_mem"$memlimits"_cpu"$cpulimits"_par"$parallel"_partsize"$part "tls-off"
else
# run test cases in both TLS=on and TLS=off modes
create_mn_distributed
create_testpod "notsame"
run_tests $size "Dist_""$size""mb_Diff_Nodes_""$currtcp""_tlsON""_mem"$memlimits"_cpu"$cpulimits"_par"$parallel"_partsize"$part "tls-on"
# now run in tls off mode
create_mn_distributed_tlsoff
create_testpod "notsame"
run_tests $size "Dist_""$size""mb_Diff_Nodes_""$currtcp""_tlsOFF""_mem"$memlimits"_cpu"$cpulimits"_par"$parallel"_partsize"$part "tls-off"
fi
}
configuration="all"
tcp="all"
ssl="all"
nodes="all"
parallel="3"
part="0"
memlimits="5120Mi"
cpulimits="4000m"
debug="no"
size="200"
while getopts t:c:s:n:m:p:b:a:l:d:f: flag
do
    case "${flag}" in
        c) configuration="${OPTARG}";;
        t) tcp="${OPTARG}";;
        s) ssl="${OPTARG}";;
        n) nodes="${OPTARG}";;
        m) memlimits="${OPTARG}";; 
        p) cpulimits="${OPTARG}";; 
        b) basedir="${OPTARG}";; 
        a) parallel="${OPTARG}";; 
        l) part="${OPTARG}";; 
        d) debug="${OPTARG}";; 
        f) size="${OPTARG}";; 
        *) usage
           exit 0;;
    esac
done
if [ -z $basedir ];then
echo "Missing -b <basedir> , need to store results"
exit 1
fi

allparams=$configuration"_"$tcp"_"$ssl"_"$memlimits"_"$cpulimits"_parall"$parallel"_partsize"$part"_"
# Start
TIMEFORMAT=%R
testtime=$(date +"%m_%d_%Y_%H_%M")
#basedir="/home/eccd/test"
testdir=$basedir"/results/"$allparams$testtime
mindir=$basedir"/results/MIN"
maxdir=$basedir"/results/MAX"
servertmp=$basedir"/results/Servertmptcpdumps"
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
echo "CPU (-p 4000m ) :  $cpulimits">>$result_file
echo "MEM (-m 5120Mi ) : $memlimits">>$result_file
echo "Parallel (-a ): $parallel">>$result_file
echo "Part Size (-l  ) : $part">>$result_file


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