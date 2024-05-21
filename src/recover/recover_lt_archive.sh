#!/bin/sh -l
#-----------------------------------------------------------------------
# Update template postproc and submit .case.lt_archive
#-----------------------------------------------------------------------
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_nco

set -euxv
mkdir -p $DIR_LOG/hindcast/recover
LOG_FILE=$DIR_LOG/hindcast/recover/recover_lt_archive_`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1

dorelaunch=0
#listofcases="sps4_199307_002 sps4_199307_003 sps4_199307_006 sps4_199307_008 sps4_199307_009"
if [[ $# -eq 0 ]]
then
   listofcases="sps4_199307_003 sps4_199307_006 sps4_199307_008 sps4_199307_009"
else
   listofcases=$1
fi
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
  sed -e "s:CASO:$caso:g;s:IC:$ic:g;s:OUTDIRC3S:$outdirC3S:g" $DIR_POST/cice/interp_cice2C3S_template.sh > $DIR_CASES/$caso/interp_cice2C3S_${caso}.sh
  chmod u+x $DIR_CASES/$caso/interp_cice2C3S_${caso}.sh
  cd $DIR_CASES/$caso
# to refresh lt_achive from template
  ./case.setup --reset
  ./xmlchange BUILD_COMPLETE=TRUE
  ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -S qos_resv -t "6" -M 15000 -j lt_archive.$caso -l $DIR_CASES/$caso/logs/ -d ${DIR_CASES}/$caso -s .case.lt_archive 
done

exit 0
