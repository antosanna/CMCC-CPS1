#!/bin/bash 
#-----------------------------------------------------------------------
# Update template postproc and submit .case.lt_archive
#-----------------------------------------------------------------------
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

#set -eu
mkdir -p $DIR_LOG/hindcast/
#LOG_FILE=$DIR_LOG/hindcast/SPS4_hindcast_checklist_all_st_`date +%Y%m%d%H%M`
#exec 3>&1 1>>${LOG_FILE} 2>&1
start_date=`date`

typeofrun="hindcast"

echo "enter the month to check (leave empty if you want all months)"
read st
echo ""
if [[ -z $st ]]
then
    echo "checking all st"
    str_st="all st"
else
    str_st=$st
fi
if [[ ! -z $st ]]
then
   search_string=${st}
   str_expected=$((30*30))
else
   str_expected=$((30*30*12))
fi
n_listadone=0
remote_mach_list="Zeus Leonardo"  
for mach in ${remote_mach_list} ; do


#   set +u
   n_done=`ls $DIR_ARCHIVE1/${SPSSystem}_${yyyy}${st}_0??.transfer_from_${mach}_DONE 2>/dev/null|wc -l`
#   set -ue
   if [[ $n_done -ne 0 ]]
   then
      n_listadone=$(($n_listadone + `ls $DIR_ARCHIVE/*${search_string}_0*.transfer_from_${mach}_DONE|wc -l`))
   fi

done #remote_mach_list
#now count completed on Juno
n_listadone=$(($n_listadone + `ls $DIR_CASES/*${search_string}_0*/logs/*moredays*_DONE|wc -l`))
echo "Total number of case run for $str_st: $n_listadone" >$SCRATCHDIR/ctr
echo "Percentage: $(($n_listadone *100/$str_expected))%">>$SCRATCHDIR/ctr
set -u
if [[ ! -z $st ]]
then
   for yyyy in {1993..2022}
   do
      n_y_done=$((`ls $DIR_ARCHIVE/*${yyyy}${st}_0*.transfer_from_*_DONE|wc -l` + `ls $DIR_CASES/*${yyyy}${st}_0*/logs/*moredays*_DONE|wc -l`))
      if [[ $n_y_done -ne 0 ]] 
      then
         echo "Total number of case run for $yyyy: $n_y_done">>$SCRATCHDIR/ctr
      fi
   done
else
   for mm in {01..12}
   do
      echo "Month start-date $mm: ">>$SCRATCHDIR/ctr
      n_m_done=0
      for yyyy in {1993..2022}
      do
         n_ym_done=$((`ls $DIR_ARCHIVE/*${yyyy}${mm}_0*.transfer_from_*_DONE|wc -l` + `ls $DIR_CASES/*${yyyy}${mm}_0*/logs/*moredays*_DONE|wc -l`))
         if [[ $n_ym_done -ne 0 ]] 
         then
            echo "    Total number of case run for $yyyy: $n_ym_done">>$SCRATCHDIR/ctr
         fi
         n_m_done=$(($n_m_done + $n_ym_done))
      done
      echo "Total number of case run for $mm: $(($n_m_done * 100/(30*30)))%">>$SCRATCHDIR/ctr
      echo " ">>$SCRATCHDIR/ctr
   done
fi
echo "======================================"
echo "Results in $SCRATCHDIR/ctr"
echo "======================================"
