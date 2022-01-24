#!/bin/bash
ver=$1
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -u 4096Mi -v 250m -p 250m -m 4096Mi -a 3 -l 0 -r $ver -n notsame
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -u 4096Mi -v 500m -p 500m -m 4096Mi -a 3 -l 0 -r $ver -n notsame
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -u 4096Mi -v 750m -p 750m -m 4096Mi -a 3 -l 0 -r $ver -n notsame
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -u 4096Mi -v 1000m -p 1000m -m 4096Mi -a 3 -l 0 -r $ver -n notsame
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -u 4096Mi -v 3000m -p 3000m -m 4096Mi -a 3 -l 0 -r $ver -n notsame
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -u 4096Mi -v 4000m -p 4000m -m 4096Mi -a 3 -l 0 -r $ver -n notsame
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -u 4096Mi -v 5000m -p 5000m -m 4096Mi -a 3 -l 0 -r $ver -n notsame
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -u 4096Mi -v 6000m -p 6000m -m 4096Mi -a 3 -l 0 -r $ver -n notsame
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -u 4096Mi -v 7000m -p 7000m -m 4096Mi -a 3 -l 0 -r $ver -n notsame
