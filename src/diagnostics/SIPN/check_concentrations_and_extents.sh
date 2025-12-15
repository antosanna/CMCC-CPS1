#!/bin/sh -l
#BSUB -o /work/cmcc/cp1/CPS/CMCC-CPS1/logs/SIPN/check_concentrations%J.out  # Appends std output to file %J.out.
#BSUB -e /work/cmcc/cp1/CPS/CMCC-CPS1/logs/SIPN/check_concentrations%J.err  # Appends std error to file %J.err.
#BSUB -J check_concentrations
#BSUB -q s_medium       # queue
#BSUB -M 10000
#BSUB -P 0490
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_cdo
. $DIR_UTIL/load_nco

set -evxu

yyyy=`date +%Y`
st=`date +%m`
st=11
. $DIR_UTIL/descr_ensemble.sh $yyyy
outdir=$WORK/CPS/CMCC-${CPSSYS}/SIPN/$yyyy$st/
wkdir=$SCRATCHDIR/SIPN
mkdir -p $wkdir

cdo -O ensstd $outdir/cmcc*concentration.nc $wkdir/cmcc_${yyyy}${st}_concentration_stdev.nc
cdo -O ensmean $outdir/cmcc*concentration.nc $wkdir/cmcc_${yyyy}${st}_concentration_mean.nc

cat $outdir/*total-area.txt >> $SCRATCHDIR/SIPN/cmcc_total-area.$yyyy$st.txt
set -euvx
sed -i "s:,:;:g" $SCRATCHDIR/SIPN/cmcc_total-area.$yyyy$st.txt
sed -i "s:\.:,:g" $SCRATCHDIR/SIPN/cmcc_total-area.$yyyy$st.txt
for ens in 001 020 048
do
   sed -e "s:,:;:g" $outdir/cmcc_${ens}_regional-area.txt > $SCRATCHDIR/SIPN/cmcc_${ens}_regional-area.$yyyy$st.txt
   sed -i "s:\.:,:g" $SCRATCHDIR/SIPN/cmcc_${ens}_regional-area.$yyyy$st.txt
done
set +euvx
. ~/load_miniconda
conda activate rclone_gdrive
for ens in 001 020 048
do
   rclone copy  $SCRATCHDIR/SIPN/cmcc_${ens}_regional-area.$yyyy$st.txt my_drive:CMCC_SEA-ICE/checks 
done
rclone copy  $SCRATCHDIR/SIPN/cmcc_total-area.$yyyy$st.txt my_drive:CMCC_SEA-ICE/checks 
