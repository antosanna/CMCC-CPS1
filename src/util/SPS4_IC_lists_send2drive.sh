#!/bin/sh -l
#-----------------------------------------------------------------------
# Update template postproc and submit .case.lt_archive
#-----------------------------------------------------------------------
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euxv
if [[ $machine != "juno" ]]
then
   echo "this script is meant to run only on Juno machine"
   exit
fi
mkdir -p $DIR_LOG/hindcast/
LOG_FILE=$DIR_LOG/hindcast/SPS4_IC_lists_send2drive_`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1

typeofrun="hindcast"
models="CAM NEMO"
set +euvx
. $DIR_UTIL/condaactivation.sh
condafunction activate $envcondarclone
set -euvx
for module in $models
do
   hindcastlist=${SPSSystem}_${typeofrun}_IC_${module}_list.csv
   hindcastlist_excel=`echo ${hindcastlist}|rev |cut -d '.' -f2-|rev`.xlsx
   if [[ -f $DIR_CHECK/$hindcastlist_excel ]]
   then
     rm $DIR_CHECK/$hindcastlist_excel
   fi
#copy the relative file from Zeus
   if [[ $module == "CAM" ]]
   then
      $DIR_UTIL/SPS4_IC_CAM_checklist.sh 
   fi
   python $DIR_UTIL/convert_csv2xls.py ${DIR_CHECK}/${hindcastlist} ${DIR_CHECK}/$hindcastlist_excel

   if [[ ! -f $DIR_CHECK/$hindcastlist_excel ]]
   then
      title="[CPS1 ERROR] $DIR_CHECK/$hindcastlist_excel checklist not produced"
      body="error in conversion from csv to xlsx $DIR_UTIL/convert_csv2xls.py "
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
   else
      rclone copy ${DIR_CHECK}/$hindcastlist_excel my_drive:
   fi
done
set +euvx
condafunction deactivate $envcondarclone
exit 0
