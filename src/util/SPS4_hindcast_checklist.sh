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


table_column_id_ndays=$(($nmonfore + 2))



cp ${DIR_CHECK}/${hindcasts_list} ${DIR_TEMP}/$listfiletocheck

remote_mach_list="zeus"   #will be also leonardo, cassandra

for mach in ${remote_mach_list} ; do
   case $mach 
   in  
     
     zeus)  case_dir=/work/csp/sps-dev/CPS/CMCC-CPS1/cases 
            arch_dir=/work/csp/sps-dev/CMCC-CM/archive 
            remote_user=sps-dev
            DIR_CASES_remote=$(echo "${DIR_CASES/cases/cases_from_Zeus}")
            remote=${remote_user}@zeus01.cmcc.scc ;;

   esac

   DIR_UTIL_remote=$(echo "${DIR_UTIL/$operational_user/$remote_user}")
   remote_st_list="`ssh $remote $DIR_UTIL_remote/findjobs.sh -J run.${SPSSystem}|cut -c 14-15|sort -u`"
   for st in $remote_st_list
   do
      n_listofcases=`ssh $remote ls -d ${arch_dir}/${SPSSystem}_[12][0-9][0-9][0-9]${st}_0??|wc -l`  
# meaning that the case has started but not yet completed a single month
      if [[ $n_listofcases -eq 0 ]]
      then
         continue
      fi
      listofcases=`ssh $remote ls -d ${arch_dir}/${SPSSystem}_[12][0-9][0-9][0-9]${st}_0??`  
     
      for casename in $listofcases 
      do 
         caso=`basename $casename` 
# calc position of the ith-column inside csv table
         LN="$(grep -n "$caso" ${DIR_TEMP}/$listfiletocheck | cut -d: -f1)"
# check if already trasnferred
         if [[ -f $DIR_ARCHIVE/$caso.transfer_from_Zeus_DONE ]]
         then
#ADD CHECK FOR POSTPROCC3S DONE ON JUNO
            check_pp_C3S_from_remote=$DIR_CASES_remote/$caso/logs/postproc_C3S_${caso}_DONE
# check if postproc C3S done
            if [[ -f $check_pp_C3S_from_remote ]]
            then
               for i in `seq 1 $(($nmonfore + 2))`
               do
                  table_column_id=$(($i + 1))
# assign a value with -val selecting a row with -v and a column with -c
                  awk -v r=$LN -v c=$table_column_id -v val='1' 'BEGIN{FS=OFS=","} NR==r{$c=val} 1' ${DIR_TEMP}/$listfiletocheck > $DIR_TEMP/$listfiletocheck.tmp1

# add 1 second wait to be sure the file has been modified
                  sleep 1
   
                  mv $DIR_TEMP/$listfiletocheck.tmp1 ${DIR_TEMP}/$listfiletocheck

               done
            else
# if transferred for sure completed so the 6 months plus moredays
               for i in `seq 1 $(($nmonfore + 1))`
               do
# position of the ith-column inside csv table
                  table_column_id=$(($i + 1))
# assign a value with -val selecting a row with -v and a column with -c
                  awk -v r=$LN -v c=$table_column_id -v val='1' 'BEGIN{FS=OFS=","} NR==r{$c=val} 1' ${DIR_TEMP}/$listfiletocheck > $DIR_TEMP/$listfiletocheck.tmp1

# add 1 second wait to be sure the file has been modified
                  sleep 1

                  mv $DIR_TEMP/$listfiletocheck.tmp1 ${DIR_TEMP}/$listfiletocheck

               done
# add 1 second wait to be sure the file has been modified
#               continue
            fi    # end if [[ -f $check_pp_C3S_from_remote ]]
         fi    # end if already trasnferred
         CASEROOT=${case_dir}/$caso   # for $check_run_moredays
         set +euvx
         . $dictionary     #fixed
         set -euvx
# not yet trasnferred but completed
         if [[ `ssh $remote ls $check_run_moredays |wc -l` -eq 1 ]]
         then
            for i in `seq 1 $(($nmonfore + 1))`
            do
# position of the ith-column inside csv table
               table_column_id=$(($i + 1))
# assign a value with -val selecting a row with -v and a column with -c
               awk -v r=$LN -v c=$table_column_id -v val='1' 'BEGIN{FS=OFS=","} NR==r{$c=val} 1' ${DIR_TEMP}/$listfiletocheck > $DIR_TEMP/$listfiletocheck.tmp1

# add 1 second wait to be sure the file has been modified
               sleep 1

               mv $DIR_TEMP/$listfiletocheck.tmp1 ${DIR_TEMP}/$listfiletocheck

            done
         else
            ndone=`ssh $remote ls ${case_dir}/$caso/logs/postproc_monthly_??????_done|wc -l` 
            if [[ $ndone -eq 0 ]]
            then
               continue
            fi

            for i in `seq 1 $ndone`
            do
# position of the ith-column inside csv table
               table_column_id=$(($i + 1))
# assign a value with -val selecting a row with -v and a column with -c
               awk -v r=$LN -v c=$table_column_id -v val='1' 'BEGIN{FS=OFS=","} NR==r{$c=val} 1' ${DIR_TEMP}/$listfiletocheck > $DIR_TEMP/$listfiletocheck.tmp1

# add 1 second wait to be sure the file has been modified
               sleep 1

               mv $DIR_TEMP/$listfiletocheck.tmp1 ${DIR_TEMP}/$listfiletocheck

            done
         fi # if `ssh $remote ls $check_run_moredays |wc -l` -eq 1 
       done #listofcases
  
    done #st

done #remote_mach_list


#now on juno
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
for col in {2..10}
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
nv ${DIR_TEMP}/$listfiletocheck ${DIR_CHECK}/${hindcasts_list}
# store the results in a file flagged by date
cp -p ${DIR_CHECK}/${hindcasts_list} ${DIR_CHECK}/${hindcasts_list}.`date +%Y%m%d%H`
# remove working temporary file
rm ${DIR_TEMP}/$listfiletocheck

set +euvx
. $DIR_UTIL/condaactivation.sh
condafunction activate $envcondarclone
set -euvx
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
condafunction deactivate $envcondarclone
exit 0
