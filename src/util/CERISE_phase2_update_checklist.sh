#!/bin/sh -l
#-----------------------------------------------------------------------
# Update template postproc and submit .case.lt_archive
#-----------------------------------------------------------------------
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_nco

set -euxv
mkdir -p $DIR_LOG/hindcast/
#LOG_FILE=$DIR_LOG/hindcast/SPS4_hindcast_checklist_`date +%Y%m%d%H%M`
#exec 3>&1 1>>${LOG_FILE} 2>&1
LOG_FILE=$DIR_LOG/hindcast/CERISE_phase2_update_checklist_hindcast_`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1

typeofrun="hindcast"
hindcasts_templ=CERISE_phase2_list.$machine.csv
hindcasts_list=CERISE_phase2_list.$machine.`date +%Y%m%d`.csv
cp $DIR_CHECK/$hindcasts_templ $DIR_CHECK/$hindcasts_list
hindcastlist_excel=`echo ${hindcasts_list}|rev |cut -d '.' -f2-|rev`.xlsx
hindcastlist_htm=`echo ${hindcasts_list}|rev |cut -d '.' -f2-|rev`.htm
if [[ -f $DIR_CHECK/$hindcastlist_excel ]]
then
  rm $DIR_CHECK/$hindcastlist_excel
fi
if [[ -f $DIR_CHECK/$hindcastlist_htm ]]
then
  rm $DIR_CHECK/$hindcastlist_htm
fi
listfiletocheck="deleteme.csv"
#copy the relative file from Zeus

table_column_id_ndays=$(($nmonfore + 2))



cp ${DIR_CHECK}/${hindcasts_list} ${DIR_TEMP}/$listfiletocheck

#find currently running start-dates
local_st_list="`$DIR_UTIL/findjobs.sh -J run.${SPSSystem}|cut -c 14-15|sort -u`"
for st in $local_st_list
do 
   n_listofcases=`ls -d ${DIR_ARCHIVE}/${SPSSystem}_[12][0-9][0-9][0-9]${st}_0??|wc -l`  
   if [[ $n_listofcases -eq 0 ]]
   then
      continue
   fi
   cd $DIR_ARCHIVE
   listofcases=`ls -d ${SPSSystem}_*${st}_0??`
   cd $DIR_CASES
   for caso in $listofcases
   do
#to avoid checking on cases run on remote and only transfered to juno 
      if [[ ! -d $DIR_CASES/$caso ]] ; then
         continue
      fi
      ndone=`ls $DIR_CASES/$caso/logs/postproc_monthly_??????_done|wc -l`
      if [[ $ndone -eq 0 ]]
      then
         continue
      fi
# calc position of the ith-column inside csv table
     # get  flag files from dictionary
      set +euvx
      CASEROOT=$DIR_CASES/$caso
      . $dictionary     #fixed
      set -euvx
      LN="$(grep -n "$caso" ${DIR_TEMP}/$listfiletocheck | cut -d: -f1)"
      if [[ -f $check_pp_C3S ]]
      then
         for i in `seq 1 $(($nmonfore + 2))`
         do
# calc position of the ith-column inside csv table
            table_column_id=$(($i + 1))
# assign a value with -val selecting a row with -v and a column with -c
            awk -v r=$LN -v c=$table_column_id -v val='1' 'BEGIN{FS=OFS=","} NR==r{$c=val} 1' ${DIR_TEMP}/$listfiletocheck > $DIR_TEMP/$listfiletocheck.tmp1

# add 1 second wait to be sure the file has been modified
            sleep 1
   
            mv $DIR_TEMP/$listfiletocheck.tmp1 ${DIR_TEMP}/$listfiletocheck

         done
      else

         CASEROOT=$DIR_CASES/$caso
         if [[ -f $check_run_moredays ]]
         then
            for i in `seq 1 $(($nmonfore + 1))`
            do
# calc position of the ith-column inside csv table
               table_column_id=$(($i + 1))
# assign a value with -val selecting a row with -v and a column with -c
               awk -v r=$LN -v c=$table_column_id -v val='1' 'BEGIN{FS=OFS=","} NR==r{$c=val} 1' ${DIR_TEMP}/$listfiletocheck > $DIR_TEMP/$listfiletocheck.tmp1

# add 1 second wait to be sure the file has been modified
               sleep 1
   
               mv $DIR_TEMP/$listfiletocheck.tmp1 ${DIR_TEMP}/$listfiletocheck

            done
         else

            for i in `seq 1 $ndone`
            do
               table_column_id=$(($i + 1))
# assign a value with -val selecting a row with -v and a column with -c
               awk -v r=$LN -v c=$table_column_id -v val='1' 'BEGIN{FS=OFS=","} NR==r{$c=val} 1' ${DIR_TEMP}/$listfiletocheck > $DIR_TEMP/$listfiletocheck.tmp1

# add 1 second wait to be sure the file has been modified
               sleep 1

               mv $DIR_TEMP/$listfiletocheck.tmp1 ${DIR_TEMP}/$listfiletocheck

            done

         fi
       fi
   done #listofcases
done #st running

# now compute total n_complete
for col in {2..8}
do
   n_completed=0
   list_completed=`tail -n +3 ${DIR_CHECK}/${hindcasts_list}|cut -d ',' -f$col`
   for ll in $list_completed
   do
      if [[ "$ll" != "0" ]]
      then
         n_completed=$(($n_completed + $ll))
      fi
   done
   awk -v r=2 -v c=$col -v val="$n_completed" 'BEGIN{FS=OFS=","} NR==r{$c=val} 1' ${DIR_TEMP}/$listfiletocheck > $DIR_TEMP/$listfiletocheck.tmp1
   sleep 1
   mv ${DIR_TEMP}/$listfiletocheck.tmp1 ${DIR_TEMP}/${listfiletocheck}
done
cp ${DIR_TEMP}/$listfiletocheck ${DIR_TEMP}/${listfiletocheck}.`date +%Y%m%d%H`
mv ${DIR_TEMP}/$listfiletocheck ${DIR_CHECK}/${hindcasts_list}
# store the results in a file flagged by date
#cp -p ${DIR_CHECK}/${hindcasts_list} ${DIR_CHECK}/${hindcasts_list}.`date +%Y%m%d%H`
# remove working temporary file
rm ${DIR_TEMP}/$listfiletocheck

set +euvx
. $DIR_UTIL/condaactivation.sh
condafunction activate $envcondarclone
set -euvx
python $DIR_UTIL/convert_csv2xls.py ${DIR_CHECK}/${hindcasts_list} ${DIR_CHECK}/$hindcastlist_excel
python $DIR_UTIL/convert_csv2htm.py ${DIR_CHECK}/${hindcasts_list} ${DIR_CHECK}/$hindcastlist_htm
sed -i '/border/a </thead>' ${DIR_CHECK}/$hindcastlist_htm
sed -i '/border/a </tr>' ${DIR_CHECK}/$hindcastlist_htm
today=`date`
sed -i "/border/a <th colspan="10">currente status $today</th>" ${DIR_CHECK}/$hindcastlist_htm
sed -i '/border/a <tr style="text-align: center;">' ${DIR_CHECK}/$hindcastlist_htm
sed -i '/border/a <thead>' ${DIR_CHECK}/$hindcastlist_htm

if [[ ! -f $DIR_CHECK/$hindcastlist_excel ]]
then
   title="[CERISE ERROR] $DIR_CHECK/$hindcastlist_excel checklist not produced"
   body="error in conversion from csv to xlsx $DIR_UTIL/convert_csv2xls.py"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
else
   rclone mkdir my_drive:CERISE
   rclone copy ${DIR_CHECK}/$hindcastlist_excel my_drive:CERISE
fi
set +euvx
condafunction deactivate 
exit 0
