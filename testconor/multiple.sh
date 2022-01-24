#!/bin/bash
usage() {
echo "Usage .. "
echo "-s 'tls-on/tls-off' (TLS on or off)"
echo "-c 'dist/sa' (Configuration is Distributed or Standalone"
echo "-t 'def/chg' (TCP settings as Default or Changed"
echo "-n 'diff' (Set this value if u do not want Standalone with same nodes)"
}
configuration=""
tcp=""
ssl=""
nodes=""
memlimits=""
cpulimits=""
basedir=""
parallel=""
part=""
while getopts t:c:s:n:m:p:b:a:l: flag
do
    case "${flag}" in
        c) configuration="-c ${OPTARG}";;
        t) tcp="-t ${OPTARG}";;
        s) ssl="-s ${OPTARG}";;
        n) nodes="-n ${OPTARG}";;
        m) memlimits="-m ${OPTARG}";;
        p) cpulimits="-p ${OPTARG}";;
        b) basedir="-b ${OPTARG}";;
        a) parallel="-a ${OPTARG}";;
        l) part="-l ${OPTARG}";;
        *) usage
           exit 0;;
    esac
done
echo "configuration is $configuration"
echo "tcp is $tcp"
echo "ssl is $ssl"
echo "nodes is $nodes"
echo "memlimits is $memlimits"
echo "cpulimits is $cpulimits"
echo "part size is $part"
echo "parallel  is $parallel"
echo "base dir is $basedir"
for i in {1..30};do

echo "Run is $i">>/home/eccd/test/multiple-tests.log
date>>/home/eccd/test/multiple-tests.log
/home/eccd/test/testAll.sh $configuration $tcp $ssl $nodes $memlimits $cpulimits $basedir $parallel $part
done
