#!/bin/bash
testfile="/home/eccd/test/fileToUpload.txt"
result=$(( 3000 * $1 ))
rm $testfile >/dev/null 2>&1


for ((i = 0 ; i <= $result ; i++)); do
echo "###########################################################################################################">>$testfile
echo "###################################### line $i ########################################################################">>$testfile
echo "####################################################################################################################">>$testfile
done

