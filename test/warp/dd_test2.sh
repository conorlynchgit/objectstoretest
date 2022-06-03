#!/bin/bash -xv
result_file=$1
ddfile="DD_test_""memlimit_"$memlimit"_cpulimit_"$cpulimit
bss="4k 6k 8k 16k 32k 64k 1M"
if="/dev/urandom"
oflag="oflag=direct"
of="/export/ddtestfile"
echo "start of script is">>$result_file
echo "bss is $bss">>$result_file
for bs in $bss;do
echo "$bs is">>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/urandom of=/export/ddtestfile bs=4k count=1000 oflag=direct >>$result_file
(kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/urandom of=/export/ddtestfile bs=4k count=1000 oflag=direct) >>$result_file
echo "aaaaa">>$result_file
kubectl exec -it po/eric-data-object-storage-mn-0 $container -n storobj-test -- dd if=/dev/urandom of=/export/ddtestfile bs=4k count=1000 oflag=direct |egrep 'MB|GB'>>$result_file
