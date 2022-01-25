#!/bin/bash
# tls OFF
# debug OFF
# multipart default
# parallel (off) 1 TCP session
# Version minio (11)
# just rename the MAX,MIN to reflect the parameters (version-multipart-parallel e.g MAX_V11_par1_multi0),
multi="multi0"
par="par3"
ver="V11"
suffix="_"$ver"_"$par"_"$multi
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 500 -m 1024Mi -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 500 -m 2048Mi -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 500 -m 3072Mi -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 500 -m 4096Mi -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 500 -m 5120Mi -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 500 -m 6144Mi -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 500 -m 15360Mi -l 0 -r 11
#
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 1000 -m 1024Mi -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 1000 -m 2048Mi -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 1000 -m 3072Mi -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 1000 -m 4096Mi -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 1000 -m 5120Mi -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 1000 -m 6144Mi -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 1000 -m 15360Mi -l 0 -r 11
#
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 2000 -m 1024Mi -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 2000 -m 2048Mi -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 2000 -m 3072Mi -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 2000 -m 4096Mi -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 2000 -m 5120Mi -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 2000 -m 6144Mi -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 2000 -m 15360Mi -l 0 -r 11
#rename the recorded MAX and MIN to reflect the session
mv /home/eccd/conor/test/results/MAX /home/eccd/conor/test/results/MAX$suffix
mv /home/eccd/conor/test/results/MIN /home/eccd/conor/test/results/MIN$suffix

multi="multi0"
par="par1"
ver="V11"
suffix="_"$ver"_"$par"_"$multi
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -l 0 -a 1 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 500 -m 1024Mi -a 1 -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 500 -m 2048Mi -a 1 -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 500 -m 3072Mi -a 1 -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 500 -m 4096Mi -a 1 -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 500 -m 5120Mi -a 1 -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 500 -m 6144Mi -a 1 -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 500 -m 15360Mi -a 1 -l 0 -r 11
#
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 1000 -m 1024Mi -a 1 -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 1000 -m 2048Mi -a 1 -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 1000 -m 3072Mi -a 1 -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 1000 -m 4096Mi -a 1 -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 1000 -m 5120Mi -a 1 -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 1000 -m 6144Mi -a 1 -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 1000 -m 15360Mi -a 1 -l 0 -r 11
#
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 2000 -m 1024Mi -a 1 -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 2000 -m 2048Mi -a 1 -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 2000 -m 3072Mi -a 1 -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 2000 -m 4096Mi -a 1 -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 2000 -m 5120Mi -a 1 -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 2000 -m 6144Mi -a 1 -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 2000 -m 15360Mi -a 1 -l 0 -r 11
mv /home/eccd/conor/test/results/MAX /home/eccd/conor/test/results/MAX$suffix
mv /home/eccd/conor/test/results/MIN /home/eccd/conor/test/results/MIN$suffix


multi="multi0"
par="par3"
ver="V14"
suffix="_"$ver"_"$par"_"$multi
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 500 -m 1024Mi -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 500 -m 2048Mi -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 500 -m 3072Mi -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 500 -m 4096Mi -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 500 -m 5120Mi -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 500 -m 6144Mi -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 500 -m 15360Mi -l 0 -r 14
#
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 1000 -m 1024Mi -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 1000 -m 2048Mi -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 1000 -m 3072Mi -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 1000 -m 4096Mi -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 1000 -m 5120Mi -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 1000 -m 6144Mi -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 1000 -m 15360Mi -l 0 -r 14
#
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 2000 -m 1024Mi -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 2000 -m 2048Mi -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 2000 -m 3072Mi -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 2000 -m 4096Mi -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 2000 -m 5120Mi -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 2000 -m 6144Mi -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 2000 -m 15360Mi -l 0 -r 14
#rename the recorded MAX and MIN to reflect the session
mv /home/eccd/conor/test/results/MAX /home/eccd/conor/test/results/MAX$suffix
mv /home/eccd/conor/test/results/MIN /home/eccd/conor/test/results/MIN$suffix

multi="multi0"
par="par1"
ver="V14"
suffix="_"$ver"_"$par"_"$multi
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -l 0 -a 1 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 500 -m 1024Mi -a 1 -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 500 -m 2048Mi -a 1 -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 500 -m 3072Mi -a 1 -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 500 -m 4096Mi -a 1 -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 500 -m 5120Mi -a 1 -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 500 -m 6144Mi -a 1 -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 500 -m 15360Mi -a 1 -l 0 -r 14
#
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 1000 -m 1024Mi -a 1 -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 1000 -m 2048Mi -a 1 -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 1000 -m 3072Mi -a 1 -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 1000 -m 4096Mi -a 1 -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 1000 -m 5120Mi -a 1 -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 1000 -m 6144Mi -a 1 -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 1000 -m 15360Mi -a 1 -l 0 -r 14
#
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 2000 -m 1024Mi -a 1 -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 2000 -m 2048Mi -a 1 -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 2000 -m 3072Mi -a 1 -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 2000 -m 4096Mi -a 1 -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 2000 -m 5120Mi -a 1 -l 0 -r 14
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 2000 -m 6144Mi -a 1 -l 0 -r 11
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 2000 -m 15360Mi -a 1 -l 0 -r 14
mv /home/eccd/conor/test/results/MAX /home/eccd/conor/test/results/MAX$suffix
mv /home/eccd/conor/test/results/MIN /home/eccd/conor/test/results/MIN$suffix
