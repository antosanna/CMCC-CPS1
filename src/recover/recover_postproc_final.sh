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

listofcases="sps4_199308_004 sps4_199308_039 sps4_199508_022 sps4_199508_031 sps4_199508_016 sps4_199508_026 sps4_199608_002 sps4_199408_034 sps4_199408_032 sps4_199408_014 sps4_199408_016 sps4_199408_017 sps4_199308_035 sps4_199408_004 sps4_199308_008 sps4_199308_011 sps4_199308_012 sps4_199308_007 sps4_199508_025 sps4_199508_024"
for caso in $listofcases 
do
  if [[ ! -d $DIR_CASES/$caso ]] ; then
    continue
  fi
  filename=$DIR_CASES/$caso/logs/ic_${caso}.txt
  while read line; do ic=`echo $line`; done < $filename
  echo $ic
   
  sed -e "s:EXPNAME:$caso:g;s:DUMMYIC:$ic:g;" $DIR_TEMPL/postproc_final.sh > $DIR_CASES/$caso/postproc_final_${caso}.sh
  chmod u+x $DIR_CASES/$caso/postproc_final_${caso}.sh
  
done

exit 0
