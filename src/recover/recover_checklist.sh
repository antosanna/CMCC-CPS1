#!/bin/sh -l
#-----------------------------------------------------------------------
# Update template postproc and submit .case.lt_archive
#-----------------------------------------------------------------------
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_nco

set -euxv
mkdir -p $DIR_LOG/hindcast/recover
LOG_FILE=$DIR_LOG/hindcast/recover/recover_checklist_`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1

typeofrun="hindcast"
hindcasts_list=${SPSSystem}_${typeofrun}_list.csv
#copy the relative file from Zeus
if [[ $machine == "juno" ]]
then
   rsync -auv sps-dev@zeus01.cmcc.scc:/users_home/csp/sps-dev/CPS/CMCC-CPS1/checklists/$hindcasts_list $DIR_CHECK
fi

cd $DIR_ARCHIVE

listofcases=`ls|grep ${SPSSystem}_`
cd $DIR_CASES
listfiletocheck="deleteme.csv"
cp ${DIR_CHECK}/${hindcasts_list} ${DIR_CHECK}/$listfiletocheck
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
  LN="$(grep -n "$caso" ${DIR_CHECK}/$listfiletocheck | cut -d: -f1)"

  for i in `seq 1 $ndone`
  do
     # calc position of the ith-column inside csv table
     table_column_id=$(($i + 1))
# assign a value with -val selecting a row with -v and a column with -c
     awk -v r=$LN -v c=$table_column_id -v val='DONE' 'BEGIN{FS=OFS=","} NR==r{$c=val} 1' ${DIR_CHECK}/$listfiletocheck > $DIR_TEMP/$listfiletocheck.tmp1

# add 1 second wait to be sure the file has been modified
     sleep 1

     mv -f $DIR_TEMP/$listfiletocheck.tmp1 ${DIR_CHECK}/$listfiletocheck

  done
  
done
mv ${DIR_CHECK}/$listfiletocheck ${DIR_CHECK}/${hindcasts_list}

if [[ $machine == "juno" ]]
then
   title="Zeus hindcast checklist"
   body="Updated hindcast checklist from Zeus "`date`
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -a ${DIR_CHECK}/${$hindcasts_list}
fi
exit 0
