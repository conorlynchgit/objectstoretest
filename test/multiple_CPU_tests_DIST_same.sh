#!/bin/bash
# remember is same and dist so this is 4 X 2CPU = 8CPU
ver=$1
node=$2
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c dist -t def -d no -u 4096Mi -v 250m -p 250m -m 4096Mi -a 3 -l 0 -r $ver -k $node -n same
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c dist -t def -d no -u 4096Mi -v 500m -p 500m -m 4096Mi -a 3 -l 0 -r $ver -k $node -n same
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c dist -t def -d no -u 4096Mi -v 750m -p 750m -m 4096Mi -a 3 -l 0 -r $ver -k $node -n same
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c dist -t def -d no -u 4096Mi -v 1000m -p 1000m -m 4096Mi -a 3 -l 0 -r $ver -k $node -n same
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c dist -t def -d no -u 4096Mi -v 2000m -p 2000m -m 4096Mi -a 3 -l 0 -r $ver -k $node -n same
