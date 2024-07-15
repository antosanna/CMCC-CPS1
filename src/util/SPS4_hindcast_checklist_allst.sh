#!/bin/sh -l
#-----------------------------------------------------------------------
# Update template postproc and submit .case.lt_archive
#-----------------------------------------------------------------------
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euxv
mkdir -p $DIR_LOG/hindcast/
#LOG_FILE=$DIR_LOG/hindcast/SPS4_hindcast_checklist_all_st_`date +%Y%m%d%H%M`
#exec 3>&1 1>>${LOG_FILE} 2>&1
start_date=`date`

typeofrun="hindcast"
hindcasts_list=${SPSSystem}_${typeofrun}_list.csv
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
if [[ $machine != "juno" ]]
then
   echo "this script should run only on juno" 
   exit
fi


set +euvx
. $DIR_UTIL/condaactivation.sh
condafunction activate $envcondarclone
set -euvx


cp $DIR_CHECK/${hindcasts_list} ${DIR_TEMP}/${hindcasts_list}_`date +%Y%m%d`
cp $DIR_CHECK/${hindcasts_list} ${DIR_TEMP}/$listfiletocheck

remote_mach_list="Zeus Leonardo"   #will be also leonardo, cassandra

for mach in ${remote_mach_list} ; do

#   DIR_CASES_remote=${DIR_CASES}/cases/cases_from_${mach}

   listadone=`ls $DIR_ARCHIVE/*.transfer_from_${mach}_DONE|rev|cut -d '/' -f1|rev|cut -d '.' -f1`
   for caso in $listadone 
   do 
      LN="$(grep -n "$caso" ${DIR_TEMP}/$listfiletocheck | cut -d: -f1)"
      python $DIR_UTIL/sostituisci_colonna_csv.py ${DIR_TEMP}/$listfiletocheck $(($nmonfore + 2)) $LN
   done #listofcases
  

done #remote_mach_list


#now on juno
#find currently running start-dates
for st in {01..12}
do 
   n_listofcases=`ls -d ${DIR_ARCHIVE}/${SPSSystem}_[12][0-9][0-9][0-9]${st}_0??|wc -l`  
   if [[ $n_listofcases -eq 0 ]]
   then
      continue
   fi
   cd ${DIR_ARCHIVE}
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
      . $dictionary     #fixed
      set -euvx
      LN="$(grep -n "$caso" ${DIR_TEMP}/$listfiletocheck | cut -d: -f1)"
      if [[ -f $check_pp_C3S ]]
      then
          python $DIR_UTIL/sostituisci_colonna_csv.py ${DIR_TEMP}/$listfiletocheck $(($nmonfore + 2)) $LN
      else

         CASEROOT=$DIR_CASES/$caso
      set +euvx
      . $dictionary     #fixed
      set -euvx
         if [[ -f $check_run_moredays ]]
         then
            python $DIR_UTIL/sostituisci_colonna_csv.py ${DIR_TEMP}/$listfiletocheck $(($nmonfore + 1)) $LN
         else
            python $DIR_UTIL/sostituisci_colonna_csv.py ${DIR_TEMP}/$listfiletocheck $ndone $LN

         fi
       fi
   done #listofcases
done #st running

cp ${DIR_TEMP}/$listfiletocheck ${DIR_TEMP}/after_juno_list.`date +%Y%m%d`.csv
#now compute the summ on columns
python $DIR_UTIL/calcola_somma_csv.py ${DIR_TEMP}/$listfiletocheck ${DIR_CHECK}/${hindcasts_list}

echo "program started at $start_date and completed at `date`"


python $DIR_UTIL/convert_csv2xls.py ${DIR_CHECK}/${hindcasts_list} ${DIR_CHECK}/$hindcastlist_excel
rsync -av $DIR_TEMPL/SPS4_hindcast_production_list_template.xlsx $DIR_CHECK/SPS4_hindcast_production_list.xlsx
python $DIR_UTIL/add_sheet_to_excel.py ${DIR_CHECK}/${hindcastlist_excel} ${DIR_CHECK}/SPS4_hindcast_production_list.xlsx
python $DIR_UTIL/convert_csv2htm.py ${DIR_CHECK}/${hindcasts_list} ${DIR_CHECK}/$hindcastlist_htm
sed -i '/border/a </thead>' ${DIR_CHECK}/$hindcastlist_htm
sed -i '/border/a </tr>' ${DIR_CHECK}/$hindcastlist_htm
today=`date`
sed -i "/border/a <th colspan="10">currente status $today</th>" ${DIR_CHECK}/$hindcastlist_htm
sed -i '/border/a <tr style="text-align: center;">' ${DIR_CHECK}/$hindcastlist_htm
sed -i '/border/a <thead>' ${DIR_CHECK}/$hindcastlist_htm

if [[ ! -f $DIR_CHECK/SPS4_hindcast_production_list.xlsx ]]
then
   title="[CPS1 ERROR] $DIR_CHECK/SPS4_hindcast_production_list.xlsx checklist not produced"
   body="error in conversion from csv to xlsx $DIR_UTIL/convert_csv2xls.py or in $DIR_UTIL/add_sheet_to_excel.py"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
else
   rclone copy ${DIR_CHECK}/SPS4_hindcast_production_list.xlsx my_drive:
fi
#condafunction deactivate $envcondarclone
exit 0
