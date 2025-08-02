#!/bin/sh -l
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh

LOG_FILE=$DIR_LOG/check_C3S.`date +%Y%m%d%H%M`.txt
exec 3>&1 1>${LOG_FILE} 2>&1
cd $WORK_C3S
st=07
for yyyy in `seq 2016 1 2016`
do
   . $DIR_UTIL/descr_ensemble.sh $yyyy
   flag_wrong=0
   for real in `seq -w 01 $nrunC3Sfore`
   do
      count=`ls ${yyyy}${st}/*r${real}*.nc|wc -l`
      if [[ $count -lt $nfieldsC3S ]]
      then
         countoce=`ls ${yyyy}${st}/*oce*r${real}*.nc|wc -l`
         countice=`ls ${yyyy}${st}/*Ice*r${real}*.nc|wc -l`
         countlnd=`ls ${yyyy}${st}/*land*r${real}*.nc|wc -l`
         countatm=`ls ${yyyy}${st}/*atm*r${real}*.nc|wc -l`
         countatm=`ls ${yyyy}${st}/*atm*12h*r${real}*.nc|wc -l`
         countatm6=`ls ${yyyy}${st}/*atm*6h*r${real}*.nc|wc -l`
         countatmfix=`ls ${yyyy}${st}/*atm*fix*r${real}*.nc|wc -l`
         countatmday=`ls ${yyyy}${st}/*atm*day*r${real}*.nc|wc -l`
         echo "${SPSSystem}_${yyyy}${st}_0$real oce files $countoce"
         echo "atm12                          files $countatm"
         echo "atm6                          files $countatm6"
         echo "atmd                          files $countatmday"
         echo "atmfix                          files $countatmfix"
         echo "land                         files $countlnd"
         echo "ice                          files $countice"
         echo "oce                          files $countoce"
         flag_wrong=1
      fi
      if [[ ! -f ${yyyy}${st}/qa_checker_ok_0${real} ]]
      then
         echo "qa checker missing   $yyyy$st  ${real}"
         flag_wrong=1  
      fi
      if [[ ! -f ${yyyy}${st}/tmpl_checker_ok_0${real} ]] 
      then
         echo "tmpl checker missing  $yyyy$st   ${real}"
         flag_wrong=1  
      fi
      if [[ ! -f ${yyyy}${st}/meta_checker_ok_0${real} ]]
      then
         echo "meta checker missing  $yyyy$st   ${real}"
         flag_wrong=1  
      fi
   done
   if [[ $flag_wrong -ne 1 ]]
   then
       echo "everything ok for startdate $yyyy$st ! go on with tar_C3S.sh"
   fi
done
