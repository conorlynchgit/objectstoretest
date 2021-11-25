#!/bin/bash
# specific test to go thru the cpu 
cpulist="1000m 2000m 3000m 4000m 5000m 6000m 7000m 8000m 9000m 10000m"
for cpu in $cpulist;do

echo "CPU is $cpu">>/home/eccd/test/multiple-tests.log
date>>/home/eccd/test/multiple-tests.log
/home/eccd/test/testAll.sh -c dist -t def -s tls-off -p $cpu 
done
