#!/bin/sh -l
#-----------------------------------------------------------------------
# Determine necessary environment variables
#-----------------------------------------------------------------------
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_nco

set -euxv
LOG_FILE=$DIR_LOG/hindcast/recover/recover_postproc_final_`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1

if [[ $# -eq 0 ]]
then
   listofcases="sps4_199307_002 sps4_199307_003 sps4_199307_006 sps4_199307_008 sps4_199307_009 sps4_199307_010 sps4_199307_011 sps4_199307_012 sps4_199307_014 sps4_199307_016 sps4_199307_017 sps4_199307_023 sps4_199307_024 sps4_199307_025 sps4_199307_029 sps4_199307_035 sps4_199307_040"
else
   listofcases=$1
fi

for caso in $listofcases 
do
  if [[ ! -d $DIR_CASES/$caso ]] ; then
    continue
  fi
  filename=$DIR_CASES/$caso/logs/ic_${caso}.txt
  while read line; do ic=`echo $line`; done < $filename
   
  sed -e "s:EXPNAME:$caso:g;s:DUMMYIC:$ic:g;" $DIR_TEMPL/postproc_final.sh > $DIR_CASES/$caso/postproc_final_${caso}.sh
  chmod u+x $DIR_CASES/$caso/postproc_final_${caso}.sh
  
done

exit 0
