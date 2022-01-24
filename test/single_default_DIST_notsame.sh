#!/bin/bash
ver=$1
basedir=`dirname "$0"`
./testAll.sh -b $basedir -s tls-off -c dist -t def -d no -a 3 -l 0 -r $ver -n notsame
#
