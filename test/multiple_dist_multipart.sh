#!/bin/bash
# specific test to go thru the cpu 
multipartlist="5 20 60 100 150 200"
for mpart in $multipartlist;do
./testAll.sh -r 20 -l $mpart
done
