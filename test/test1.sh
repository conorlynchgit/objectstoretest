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
#rename the recorded MAX and MIN to reflect the session
mv /home/eccd/conor/test/results/MAX /home/eccd/conor/test/results/MAX$suffix
mv /home/eccd/conor/test/results/MIN /home/eccd/conor/test/results/MIN$suffix
