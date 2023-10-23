#!/bin/sh -l
#BSUB  -J launch_create_eda
#BSUB  -q s_long
#BSUB  -o logs/launch_create_eda.out.%J  
#BSUB  -e logs/launch_create_eda.err.%J  
#BSUB  -P 0490

. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
set -euvx
yy=1991
mm=12

finalyy="2022"
finalmm="12"

repository=/data/csp/cp1/CMCC-CPS1/files4CPS1/templates4CLM
for n in `seq 1 3` ; do
  finaldir=/data/csp/cp1/CMCC-CPS1/inputs/FORC4CLM/EDA_n$n
  while [[ ${yy}${mm} -le $finalyy$finalmm ]] ; do
      echo $yy$mm
      if [[ $yy$mm -eq 196906 ]] ; then
         st=07     #`date -d ' '$yy${mm}01' + 1 month' +%m`
         yyyy=1969 #`date -d ' '$yy${mm}01' + 1 month' +%Y`
      elif [[ $yy$mm -eq 197506 ]] ; then
         st=07     #`date -d ' '$yy${mm}01' + 1 month' +%m`
         yyyy=1975 #`date -d ' '$yy${mm}01' + 1 month' +%Y`
      else
         st=`date -d ' '$yy${mm}01' + 1 month' +%m`
         yyyy=`date -d ' '$yy${mm}01' + 1 month' +%Y`
      fi 
      ln -sf  ${repository}/Precip/clmforc.GSWP3.c2011.0.5x0.5.Prec.1901-$st.nc ${finaldir}/Precip/clmforc.EDA${n}.0.5d.Prec.${yyyy}-${st}.nc
      ln -sf  ${repository}/Solar/clmforc.GSWP3.c2011.0.5x0.5.Solr.1901-$st.nc ${finaldir}/Solar/clmforc.EDA${n}.0.5d.Solr.${yyyy}-${st}.nc
      ln -sf  ${repository}/TPHWL/clmforc.GSWP3.c2011.0.5x0.5.TPQWL.1901-$st.nc ${finaldir}/TPHWL/clmforc.EDA${n}.0.5d.TPQWL.${yyyy}-${st}.nc
      mm=${st}   #`date -d ' '$yy${mm}01' + 1 month' +%m`
      yy=${yyyy} #`date -d ' '$yy${mm}01' + 1 month' +%Y`     
  done
done
