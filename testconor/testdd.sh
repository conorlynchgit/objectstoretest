#!/bin/bash
create_mn_standalone_tlsoff() {
replicas=1
helm uninstall eric-data-object-storage-mn -n $ns >/dev/null 2>&1
sleep 20
kubectl delete pvc export-eric-data-object-storage-mn-0 -n $ns >/dev/null 2>&1
kubectl delete pvc export-eric-data-object-storage-mn-1 -n $ns >/dev/null 2>&1
kubectl delete pvc export-eric-data-object-storage-mn-2 -n $ns >/dev/null 2>&1
kubectl delete pvc export-eric-data-object-storage-mn-3 -n $ns >/dev/null 2>&1
sleep 60
helm install eric-data-object-storage-mn $helm_rel --namespace=$ns --set mode=standalone --set replicas=1 $memsetlimit $cpusetlimit --set credentials.kubernetesSecretName=test-secret --set autoEncryption.enabled=false --set global.security.tls.enabled=false --set persistentVolumeClaim.size=40Gi
#helm install eric-data-object-storage-mn /home/eccd/conor/test/mn/eric-data-object-storage-mn --set server.resources.requests.cpu=250m --namespace=$ns --set mode=standalone --set replicas=1 $memsetlimit $cpusetlimit --set credentials.kubernetesSecretName=test-secret --set autoEncryption.enabled=false --set global.security.tls.enabled=false --set persistentVolumeClaim.size=40Gi
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

run_tests() {
echo "Start tests.. dd a file" >>$result_file
if [ $oneset == "4k" ];then
echo "<---4k----(Cache:zero,urandom DIRECT:zero,urandom>" >>$result_file
echo "Cache:" >>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/zero of=/export/ddfile bs=4k count=1000 
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/zero of=/export/ddfile bs=4k count=1000 |egrep 'MB/s|GB/s'|awk -F, '{print $NF}'
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/zero of=/export/ddfile bs=4k count=1000 |egrep 'MB/s|GB/s'|awk -F, '{print $NF}'>>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- \rm -rf /export/ddfile
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/urandom of=/export/ddfile bs=4k count=1000 |egrep 'MB/s|GB/s'|awk -F, '{print $NF}'>>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- \rm -rf /export/ddfile
echo "Direct:" >>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/zero of=/export/ddfile bs=4k count=1000 oflag=direct |egrep 'MB/s|GB/s'|awk -F, '{print $NF}'>>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- \rm -rf /export/ddfile
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/urandom of=/export/ddfile bs=4k count=1000 oflag=direct |egrep 'MB/s|GB/s'|awk -F, '{print $NF}'>>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- \rm -rf /export/ddfile
echo "#################################################"
else

echo "<---8k----(Cache:zero,urandom DIRECT:zero,urandom>" >>$result_file
echo "Cache:" >>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/zero of=/export/ddfile bs=8k count=1000 |egrep 'MB/s|GB/s'|awk -F, '{print $NF}'>>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- \rm -rf /export/ddfile
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/urandom of=/export/ddfile bs=8k count=1000 |egrep 'MB/s|GB/s'|awk -F, '{print $NF}'>>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- \rm -rf /export/ddfile
echo "Direct:" >>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/zero of=/export/ddfile bs=8k count=1000 oflag=direct |egrep 'MB/s|GB/s'|awk -F, '{print $NF}'>>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- \rm -rf /export/ddfile
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/urandom of=/export/ddfile bs=8k count=1000 oflag=direct |egrep 'MB/s|GB/s'|awk -F, '{print $NF}'>>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- \rm -rf /export/ddfile
echo "#################################################"
echo "<---16k----(Cache:zero,urandom DIRECT:zero,urandom>" >>$result_file
echo "Cache:" >>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/zero of=/export/ddfile bs=16k count=1000 |egrep 'MB/s|GB/s'|awk -F, '{print $NF}'>>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- \rm -rf /export/ddfile
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/urandom of=/export/ddfile bs=16k count=1000 |egrep 'MB/s|GB/s'|awk -F, '{print $NF}'>>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- \rm -rf /export/ddfile
echo "Direct:" >>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/zero of=/export/ddfile bs=16k count=1000 oflag=direct |egrep 'MB/s|GB/s'|awk -F, '{print $NF}'>>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- \rm -rf /export/ddfile
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/urandom of=/export/ddfile bs=16k count=1000 oflag=direct |egrep 'MB/s|GB/s'|awk -F, '{print $NF}'>>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- \rm -rf /export/ddfile
echo "#################################################"
echo "<---32k----(Cache:zero,urandom DIRECT:zero,urandom>" >>$result_file
echo "Cache:" >>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/zero of=/export/ddfile bs=32k count=1000 |egrep 'MB/s|GB/s'|awk -F, '{print $NF}'>>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- \rm -rf /export/ddfile
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/urandom of=/export/ddfile bs=32k count=1000 |egrep 'MB/s|GB/s'|awk -F, '{print $NF}'>>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- \rm -rf /export/ddfile
echo "Direct:" >>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/zero of=/export/ddfile bs=32k count=1000 oflag=direct |egrep 'MB/s|GB/s'|awk -F, '{print $NF}'>>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- \rm -rf /export/ddfile
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/urandom of=/export/ddfile bs=32k count=1000 oflag=direct |egrep 'MB/s|GB/s'|awk -F, '{print $NF}'>>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- \rm -rf /export/ddfile
echo "#################################################"
echo "<---64k----(Cache:zero,urandom DIRECT:zero,urandom>" >>$result_file
echo "Cache:" >>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/zero of=/export/ddfile bs=64k count=1000 |egrep 'MB/s|GB/s'|awk -F, '{print $NF}'>>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- \rm -rf /export/ddfile
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/urandom of=/export/ddfile bs=64k count=1000 |egrep 'MB/s|GB/s'|awk -F, '{print $NF}'>>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- \rm -rf /export/ddfile
echo "Direct:" >>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/zero of=/export/ddfile bs=64k count=1000 oflag=direct |egrep 'MB/s|GB/s'|awk -F, '{print $NF}'>>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- \rm -rf /export/ddfile
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/urandom of=/export/ddfile bs=64k count=1000 oflag=direct |egrep 'MB/s|GB/s'|awk -F, '{print $NF}'>>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- \rm -rf /export/ddfile
echo "#################################################"
echo "<---128k----(Cache:zero,urandom DIRECT:zero,urandom>" >>$result_file
echo "Cache:" >>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/zero of=/export/ddfile bs=128k count=1000 |egrep 'MB/s|GB/s'|awk -F, '{print $NF}'>>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- \rm -rf /export/ddfile
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/urandom of=/export/ddfile bs=128k count=1000 |egrep 'MB/s|GB/s'|awk -F, '{print $NF}'>>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- \rm -rf /export/ddfile
echo "Direct:" >>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/zero of=/export/ddfile bs=128k count=1000 oflag=direct |egrep 'MB/s|GB/s'|awk -F, '{print $NF}'>>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- \rm -rf /export/ddfile
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/urandom of=/export/ddfile bs=128k count=1000 oflag=direct |egrep 'MB/s|GB/s'|awk -F, '{print $NF}'>>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- \rm -rf /export/ddfile
echo "#################################################"
echo "<---1M----(Cache:zero,urandom DIRECT:zero,urandom>" >>$result_file
echo "Cache:" >>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/zero of=/export/ddfile bs=1M count=1000 |egrep 'MB/s|GB/s'|awk -F, '{print $NF}'>>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- \rm -rf /export/ddfile
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/urandom of=/export/ddfile bs=1M count=1000 |egrep 'MB/s|GB/s'|awk -F, '{print $NF}'>>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- \rm -rf /export/ddfile
echo "Direct:" >>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/zero of=/export/ddfile bs=1M count=1000 oflag=direct |egrep 'MB/s|GB/s'|awk -F, '{print $NF}'>>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- \rm -rf /export/ddfile
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/urandom of=/export/ddfile bs=1M count=1000 oflag=direct |egrep 'MB/s|GB/s'|awk -F, '{print $NF}'>>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- \rm -rf /export/ddfile
echo "#################################################"
echo "<---64M----(Cache:zero,urandom DIRECT:zero,urandom>" >>$result_file
echo "Cache:" >>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/zero of=/export/ddfile bs=64M count=100 |egrep 'MB/s|GB/s'|awk -F, '{print $NF}'>>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- \rm -rf /export/ddfile
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/urandom of=/export/ddfile bs=64M count=100 |egrep 'MB/s|GB/s'|awk -F, '{print $NF}'>>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- \rm -rf /export/ddfile
echo "Direct:" >>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/zero of=/export/ddfile bs=64M count=100 oflag=direct |egrep 'MB/s|GB/s'|awk -F, '{print $NF}'>>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- \rm -rf /export/ddfile
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/urandom of=/export/ddfile bs=64M count=100 oflag=direct |egrep 'MB/s|GB/s'|awk -F, '{print $NF}'>>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- \rm -rf /export/ddfile
fi
}
oneset="4k"
result_file="/home/eccd/conor/test/results/dd_result"
rel11=https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-eric-data-object-storage-mn-released-helm/eric-data-object-storage-mn/eric-data-object-storage-mn-1.11.0+19.tgz
rel14=https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-eric-data-object-storage-mn-released-helm/eric-data-object-storage-mn/eric-data-object-storage-mn-1.14.0-41.tgz
cpu_list="500 1000 2000 3000 4000"
mem_list="512Mi 1024Mi 2048Mi 3072Mi 4096Mii"
bs_sizes="4k 8k 16k 32k 1M 64M"
file_sixe=""
ns="storobj-test"
container=""
while getopts t:c:s:n:m:p:b:a:l:d:f:e:r: flag
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
        e) ns="${OPTARG}";;
        r) rel="${OPTARG}";;
        *) usage
           exit 0;;
    esac
done
if [ -z $rel ];then
echo "Missing -r <Object Store main release>"
exit 1
fi

if [ $rel == 11 ];then
helm_rel=$rel11
elif [ $rel == 14 ];then
helm_rel=$rel14
fi
\rm -rf $result_file >/dev/null 2>&1
echo "Start of DD testing" > $result_file
for cpu in $cpu_list;do
cpulimits=$cpu
 for mem in $mem_list;do
  echo "##########################" >> $result_file
  echo "####### CPU is $cpu ######" >> $result_file
  echo "####### Mem is $mem ######" >> $result_file
  echo "##########################" >> $result_file
  memlimits=$mem

 memsetlimit="--set server.resources.limits.memory=$memlimits"
 cpusetlimit="--set server.resources.limits.cpu=$cpulimits"
 create_mn_standalone_tlsoff
 run_tests
 done
done
