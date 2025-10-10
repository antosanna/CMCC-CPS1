#!/bin/sh -l
#-----------------------------------------------------------------------
# Determine necessary environment variables
#-----------------------------------------------------------------------
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_nco

set -euxv
LOG_FILE=$DIR_LOG/hindcast/recover/recover_interpORCA_`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1

dorelaunch=0
listofcases="sps4_199308_027 sps4_199308_039 sps4_199308_004 sps4_199308_005 sps4_199308_007 sps4_199308_008 sps4_199308_011 sps4_199308_012"
for caso in $listofcases 
do
  if [[ ! -d $DIR_CASES/$caso ]] ; then
    continue
  fi
  yyyy=`echo $caso|cut -d'_' -f2 |cut -c1-4`
  st=`echo $caso|cut -d'_' -f2 |cut -c5-6`
  filename=$DIR_CASES/$caso/logs/ic_${caso}.txt
  while read line; do ic=`echo $line`; done < $filename
  outdirC3S=$DIR_ARCHIVE/C3S/$yyyy$st/
  echo $ic
  echo $outdirC3S
  sed -e "s:CASO:$caso:g;s:IC:$ic:g;s:OUTDIRC3S:$outdirC3S:g" $DIR_POST/nemo/interp_ORCA2_1X1_gridT2C3S_template.sh > $DIR_CASES/$caso/interp_ORCA2_1X1_gridT2C3S_${caso}.sh
  chmod u+x $DIR_CASES/$caso/interp_ORCA2_1X1_gridT2C3S_${caso}.sh
  
#now check for interpORCA submission
  numbnemoout=`ls ${DIR_ARCHIVE}/${caso}/ocn/hist/${caso}_*.zip.nc |wc -l`  #number of total nemo output after 6 month should be $nmb_nemo_dmofiles 
  if [[ $numbnemoout -eq  $nmb_nemo_dmofiles ]] ; then
     dorelaunch=1
  else
     dorelaunch=0
  fi
  if [[ $dorelaunch -eq 1 ]] ; then
      running=0
      input="$running"
      ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_s -S $qos -M 8000 -j interp_ORCA2_1X1_gridT2C3S_${caso} -l $DIR_CASES/$caso/logs/ -d ${DIR_CASES}/$caso -s interp_ORCA2_1X1_gridT2C3S_${caso}.sh -i "$input" 
  fi
done

exit 0
