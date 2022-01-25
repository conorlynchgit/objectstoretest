#!/bin/bash
# specific test to go thru the cpu 
cpulist="1000m 2000m 3000m 4000m 5000m 6000m 7000m 8000m 9000m 10000m"
memlist="1024Mi 2048Mi 3072Mi 4096Mi 5120Mi 6144Mi 7168Mi"
for mem in $memlist;do

echo "MEM is $mem">>/home/eccd/test/multiple-tests.log
date>>/home/eccd/test/multiple-tests.log
/home/eccd/test/testAll.sh -c dist -t def -s tls-off -m $mem 
done
