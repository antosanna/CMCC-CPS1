#!/bin/sh -l
#BSUB -J mv_back
#BSUB -e /work/csp/cp1/scratch/ANTO/tmp/mv_back%J.err
#BSUB -o /work/csp/cp1/scratch/ANTO/tmp/mv_back%J.out
#BSUB -P 0490
#BSUB -M 1000

# load variables from descriptor
set +euvx
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/descr_ensemble.sh 1993
set -euvx


cd /work/csp/cp1/test_archive/CPS/CPS1/
lista=`ls -d *`
for dd in $lista
do
    rsync -auv --remove-source-files $dd/ocn/hist/* $DIR_ARCHIVE/$dd/ocn/hist/
done

