#!/bin/sh -l
#BSUB -M 1000
#BSUB -q s_medium
#BSUB -o /work/cmcc/cp1/CPS/CMCC-CPS1/logs/hindcast/monPS//extract_monthly_PS.stdout.%J
#BSUB -e /work/cmcc/cp1/CPS/CMCC-CPS1/logs/hindcast/monPS/extract_monthly_PS.stderr.%J
#BSUB -J extract_monthly_PS
#BSUB -P 0490

. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_cdo

set -evxu
dbg=0
dirwork=$SCRATCHDIR/extrapTZ/monthly_PS/
echo 'extract STARTS ' `date`
for yyyy in {1993..2022}
do
for st in 10 11 12 01
do
for mm in {01..30}
do
   caso=sps4_${yyyy}${st}_0${mm}
#------------------------------------
   wkdir=$dirwork/$caso
   mkdir -p $wkdir
   if [[ -f $wkdir/PS.$caso.C3S.nc ]]
   then
      continue
   fi
   cd $wkdir
   listafiles=`ls $DIR_ARCHIVE1/$caso/atm/hist/sps4_${yyyy}${st}_0${mm}.cam.h0.*zip.nc`
   ic=0
   for ff in $listafiles
   do
      ic=$(($ic + 1))
      cdo -selvar,PS $ff PS.$caso.$ic.nc
   done
   cdo mergetime PS.$caso.?.nc PS.$caso.nc
   cdo remapbil,$REPOGRID/griddes_C3S.txt PS.$caso.nc PS.$caso.C3S.nc
   rm PS.$caso.nc PS.$caso.?.nc
   if [[ $dbg -eq 1 ]]
   then
      exit
   fi
done
done
done
