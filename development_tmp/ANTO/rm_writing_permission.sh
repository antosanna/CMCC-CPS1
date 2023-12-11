#!/bin/sh -l
#BSUB -J rm_permission
#BSUB -e /work/csp/cp1/scratch/ANTO/tmp/rm_permission%J.err
#BSUB -o /work/csp/cp1/scratch/ANTO/tmp/rm_permission%J.out
#BSUB -P 0490
#BSUB -M 1000

# load variables from descriptor
set +euvx
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/descr_ensemble.sh 1993
set -euvx


cd $DIR_ARCHIVE
lista="sps4_199307_003 sps4_199307_006 sps4_199307_008 sps4_199307_009 sps4_199307_010 sps4_199307_011 sps4_199307_012 sps4_199307_014 sps4_199307_016 sps4_199307_017 sps4_199307_023 sps4_199307_024 sps4_199307_025 sps4_199307_029 sps4_199407_003 sps4_199407_012 sps4_199407_017 sps4_199407_020 sps4_199407_022 sps4_199407_023 sps4_199407_025 sps4_199407_027 sps4_199407_028 sps4_199407_029 sps4_199407_032 sps4_199407_034 sps4_199407_037 sps4_199507_006 sps4_199507_008 sps4_199507_009 sps4_199507_010 sps4_199507_012 sps4_199507_014 sps4_199507_015 sps4_199507_016 sps4_199507_017 sps4_199507_025 sps4_199507_032 sps4_199507_033 sps4_199507_034 sps4_199507_037 sps4_199607_001 sps4_199607_002 sps4_199607_005"
for dd in $lista
do
    chmod u-w -R $dd
done

