#!/bin/bash
ver=$1
ns=$2
basedir=`dirname "$0"`
bash -xv ./testAll.sh -b $basedir -s tls-off -c dist -t def -d no -a 3 -l 0 -r $ver -e $ns -n notsame
#
