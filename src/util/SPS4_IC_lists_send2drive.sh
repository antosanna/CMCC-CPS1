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
for module in $models
do
   hindcastlist=${SPSSystem}_${typeofrun}_IC_${module}_list.csv
   hindcastlist_excel=`echo ${hindcastlist}|rev |cut -d '.' -f2-|rev`.xlsx
   hindcastlist_htm=`echo ${hindcastlist}|rev |cut -d '.' -f2-|rev`.htm
   if [[ -f $DIR_CHECK/$hindcastlist_excel ]]
   then
     rm $DIR_CHECK/$hindcastlist_excel
   fi
   if [[ -f $DIR_CHECK/$hindcastlist_htm ]]
   then
     rm $DIR_CHECK/$hindcastlist_htm
   fi
#copy the relative file from Zeus
   if [[ $module == "CAM" ]]
   then
      $DIR_UTIL/SPS4_IC_CAM_checklist.sh 
   fi
   python $DIR_UTIL/convert_csv2xls.py ${DIR_CHECK}/${hindcastlist} ${DIR_CHECK}/$hindcastlist_excel
   python $DIR_UTIL/convert_csv2htm.py ${DIR_CHECK}/${hindcastlist} ${DIR_CHECK}/$hindcastlist_htm

   if [[ ! -f $DIR_CHECK/$hindcastlist_htm ]]
   then
      title="[CPS1 ERROR] $DIR_CHECK/$hindcastlist_htm checklist not produced"
      body="error in conversion from csv to htm $DIR_UTIL/convert_csv2htm.py "
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
   fi
   if [[ ! -f $DIR_CHECK/$hindcastlist_excel ]]
   then
      title="[CPS1 ERROR] $DIR_CHECK/$hindcastlist_excel checklist not produced"
      body="error in conversion from csv to xlsx $DIR_UTIL/convert_csv2xls.py "
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
   else
      listaf=${DIR_CHECK}/$hindcastlist_excel
      mkdir -p $DIR_LOG/wrapper
      ${DIR_UTIL}/submitcommand.sh -m $machine -M 1000 -t 4 -q $serialq_rclone -j rclone_wrapper_IC_CAM -l $DIR_LOG/wrapper/ -d ${DIR_UTIL} -s rclone_wrapper.sh -i "$typeofrun/IC_CAM '${listaf}'"
   fi
done
exit 0
