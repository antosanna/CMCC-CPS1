#!/bin/sh -l
#BSUB -J rm_permission
#BSUB -e /work/csp/sps-dev/scratch/ANTO/tmp/rm_permission%J.err
#BSUB -o /work/csp/sps-dev/scratch/ANTO/tmp/rm_permission%J.out
#BSUB -P 0490
#BSUB -M 1000

# load variables from descriptor
set +euvx
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/descr_ensemble.sh 1993
set -euvx


cd $DIR_ARCHIVE
lista="sps4_199308_004 sps4_199308_005 sps4_199308_007 sps4_199308_008 sps4_199308_011 sps4_199308_012 sps4_199308_014 sps4_199308_018 sps4_199308_019 sps4_199308_020 sps4_199308_025 sps4_199308_027 sps4_199308_035 sps4_199308_038 sps4_199308_039 sps4_199408_004 sps4_199408_014 sps4_199408_019 sps4_199408_022 sps4_199408_032 sps4_199408_034 sps4_199508_017 sps4_199508_019 sps4_199508_027 sps4_199508_029 sps4_199508_032 sps4_199508_033 sps4_199508_037 sps4_199508_040 sps4_199608_003 sps4_199608_005 sps4_199608_008 sps4_199608_010 sps4_199608_014 sps4_199608_016 sps4_199608_018 sps4_199608_023 sps4_199608_024 sps4_199608_027 sps4_199608_036 sps4_199608_040 sps4_199708_001 sps4_199708_002 sps4_199708_018 sps4_199708_027 sps4_199708_028 sps4_199808_009 sps4_199808_010 sps4_199808_012 sps4_199808_013 sps4_199808_015 sps4_199808_016"
for dd in $lista
do
    chmod u-w -R $dd
done

