#!/bin/bash
# tls OFF
# debug OFF
# multipart OFF
# parallel OFF

/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -a 1 -l 0
/home/eccd/conor/test/testAll.sh -b /home/eccd/conor/test -s tls-off -c sa -t def -d no -p 1000  -m  -a 1 -l 0

