#!/bin/sh -l
#-----------------------------------------------------------------------
# Update template postproc and submit .case.lt_archive
#-----------------------------------------------------------------------
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_nco

set -euxv
mkdir -p $DIR_LOG/hindcast/
LOG_FILE=$DIR_LOG/hindcast/SPS4_hindcast_checklist_`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1

typeofrun="hindcast"
hindcasts_list=${SPSSystem}_${typeofrun}_list.csv
hindcastlist_excel=`echo ${hindcasts_list}|rev |cut -d '.' -f2-|rev`.xlsx
if [[ -f $DIR_CHECK/$hindcastlist_excel ]]
then
  rm $DIR_CHECK/$hindcastlist_excel
fi
listfiletocheck="deleteme.csv"
#copy the relative file from Zeus
if [[ $machine == "juno" ]]
then
   rsync -auv sps-dev@zeus01.cmcc.scc:/users_home/csp/sps-dev/CPS/CMCC-CPS1/checklists/$hindcasts_list $DIR_CHECK/
   cp $DIR_CHECK/$hindcasts_list $DIR_CHECK/${SPSSystem}_${typeofrun}_list_zeus.csv
fi

cd $DIR_ARCHIVE

table_column_id_ndays=$(($nmonfore + 2))
if [[ $machine == "juno" ]]
then
   n_complete=`grep TOTAL ${DIR_CHECK}/${hindcasts_list} |cut -d ',' -f $(( $nmonfore + 2))`
else
   n_complete=0
fi
listofcases=`ls|grep ${SPSSystem}_[12]`
cd $DIR_CASES
cp ${DIR_CHECK}/${hindcasts_list} ${DIR_TEMP}/$listfiletocheck
for caso in $listofcases 
do
  if [[ ! -d $DIR_CASES/$caso ]] ; then
    continue
  fi
  ndone=`ls $DIR_CASES/$caso/logs/postproc_monthly_??????_done|wc -l` 
  if [[ $ndone -eq 0 ]]
  then
     continue
  fi
  # find line number
  LN="$(grep -n "$caso" ${DIR_TEMP}/$listfiletocheck | cut -d: -f1)"

  for i in `seq 1 $ndone`
  do
     # calc position of the ith-column inside csv table
     table_column_id=$(($i + 1))
# assign a value with -val selecting a row with -v and a column with -c
     awk -v r=$LN -v c=$table_column_id -v val='1' 'BEGIN{FS=OFS=","} NR==r{$c=val} 1' ${DIR_TEMP}/$listfiletocheck > $DIR_TEMP/$listfiletocheck.tmp1

# add 1 second wait to be sure the file has been modified
     sleep 1

     mv -f $DIR_TEMP/$listfiletocheck.tmp1 ${DIR_TEMP}/$listfiletocheck

  done
  CASEROOT=$DIR_CASES/$caso
# get  check_run_moredays from dictionary
  set +euvx
  . $dictionary     #fixed
  set -euvx
  if [[ -f $check_run_moredays ]]
  then
     table_column_id=$(($table_column_id + 1))
# assign a value with -val selecting a row with -v and a column with -c
     awk -v r=$LN -v c=$table_column_id -v val='1' 'BEGIN{FS=OFS=","} NR==r{$c=val} 1' ${DIR_TEMP}/$listfiletocheck > $DIR_TEMP/$listfiletocheck.tmp1
# add 1 second wait to be sure the file has been modified
     n_complete=$(($n_complete + 1))
     sleep 1

     mv -f $DIR_TEMP/$listfiletocheck.tmp1 ${DIR_TEMP}/$listfiletocheck
  fi
  if [[ -f $check_pp_C3S ]]
  then
# assign a value with -val selecting a row with -v and a column with -c
     awk -v r=$LN -v c=$table_column_id_ndays -v val='1' 'BEGIN{FS=OFS=","} NR==r{$c=val} 1' ${DIR_TEMP}/$listfiletocheck > $DIR_TEMP/$listfiletocheck.tmp1
# add 1 second wait to be sure the file has been modified
     sleep 1

     mv -f $DIR_TEMP/$listfiletocheck.tmp1 ${DIR_TEMP}/$listfiletocheck
  fi
  
done
awk -v r=2 -v c=$table_column_id_ndays -v val="$n_complete" 'BEGIN{FS=OFS=","} NR==r{$c=val} 1' ${DIR_TEMP}/$listfiletocheck > $DIR_TEMP/$listfiletocheck.tmp1
sleep 1
if [[ ! -f ${DIR_TEMP}/$listfiletocheck.tmp1 ]]
then
   echo "not found"
fi
mv ${DIR_TEMP}/$listfiletocheck.tmp1 ${DIR_CHECK}/${hindcasts_list}
rm ${DIR_TEMP}/$listfiletocheck


if [[ $machine == "juno" ]]
then
   set +euvx
   . $DIR_UTIL/condaactivation.sh
   condafunction activate $envcondarclone
   set -euvx
   python $DIR_UTIL/convert_csv2xls.py ${DIR_CHECK}/${hindcasts_list} ${DIR_CHECK}/$hindcastlist_excel

   if [[ -f $DIR_CHECK/$hindcastlist_excel ]]
   then
      title="[CPS1 ERROR] $DIR_CHECK/$hindcastlist_excel checklist not produced"
      body="error in conversion from csv to xlsx $DIR_UTIL/convert_csv2xls.py "
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
   fi
   rclone copy ${DIR_CHECK}/$hindcastlist_excel my_drive:
   condafunction deactivate $envcondarclone
fi
exit 0
