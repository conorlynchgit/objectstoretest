#!/bin/bash
# specific test to go thru the cpu 
multipartlist="5 60 100 200"
for mpart in $multipartlist;do
./testAll.sh -r 20 -l $mpart
done
