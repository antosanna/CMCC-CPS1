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


n_complete=0

cp ${DIR_CHECK}/${hindcasts_list} ${DIR_TEMP}/$listfiletocheck

remote_mach_list="zeus"   #will be also leonardo, cassandra

for mach in ${remote_mach_list} ; do
   case $mach 
   in  
     
     zeus)  case_dir=/work/csp/sps-dev/CPS/CMCC-CPS1/cases 
            arch_dir=/work/csp/sps-dev/CMCC-CM/archive 
            remote_user=sps-dev
            remote=${remote_user}@zeus01.cmcc.scc ;;

   esac

   DIR_UTIL_remote=$(echo "${DIR_UTIL/$operational_user/$remote_user}")
   remote_st_list="`ssh $remote $DIR_UTIL_remote/findjobs.sh -J run.${SPSSystem}|cut -c 14-15|sort -u`"
   for st in $remote_st_list
   do
      listofcases=`ssh $remote ls -d ${arch_dir}/${SPSSystem}_[12][0-9][0-9][0-9]${st}_0??`  
     
      for casename in $listofcases 
      do 
          caso=`basename $casename` 
          CASEROOT=${case_dir}/$caso   # for $check_run_moredays
          set +euvx
          . $dictionary     #fixed
          set -euvx
       # find line number
          LN="$(grep -n "$caso" ${DIR_TEMP}/$listfiletocheck | cut -d: -f1)"
          if [[ `ssh $remote ls $check_run_moredays |wc -l` -eq 1 ]]
          then
             for i in `seq 1 $ndone`
             do
# calc position of the ith-column inside csv table
                table_column_id=$(($i + 1))
# assign a value with -val selecting a row with -v and a column with -c
                awk -v r=$LN -v c=$table_column_id -v val='1' 'BEGIN{FS=OFS=","} NR==r{$c=val} 1' ${DIR_TEMP}/$listfiletocheck > $DIR_TEMP/$listfiletocheck.tmp1

# add 1 second wait to be sure the file has been modified
                sleep 1

                mv $DIR_TEMP/$listfiletocheck.tmp1 ${DIR_TEMP}/$listfiletocheck

             done
             table_column_id=$table_column_id_ndays
             awk -v r=$LN -v c=$table_column_id -v val='1' 'BEGIN{FS=OFS=","} NR==r{$c=val} 1' ${DIR_TEMP}/$listfiletocheck > $DIR_TEMP/$listfiletocheck.tmp1
# add 1 second wait to be sure the file has been modified
             n_complete=$(($n_complete + 1))
             sleep 1

             mv $DIR_TEMP/$listfiletocheck.tmp1 ${DIR_TEMP}/$listfiletocheck
          else
             ndone=`ssh $remote ls ${case_dir}/$caso/logs/postproc_monthly_??????_done|wc -l` 
             if [[ $ndone -eq 0 ]]
             then
                continue
             fi

             for i in `seq 1 $ndone`
             do
# calc position of the ith-column inside csv table
                table_column_id=$(($i + 1))
# assign a value with -val selecting a row with -v and a column with -c
                awk -v r=$LN -v c=$table_column_id -v val='1' 'BEGIN{FS=OFS=","} NR==r{$c=val} 1' ${DIR_TEMP}/$listfiletocheck > $DIR_TEMP/$listfiletocheck.tmp1

# add 1 second wait to be sure the file has been modified
                sleep 1

                mv $DIR_TEMP/$listfiletocheck.tmp1 ${DIR_TEMP}/$listfiletocheck

             done
# get  check_run_moredays from dictionary
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# THIS SECTION IS COMMENTED BECAUSE WE DECIDED TO RUN THE POSTPROC FOR C3S 
# COMPLETELY ON JUNO MACHINE FOR CONSISTENCY REASONS

#       remote_check_pp_C3S=$(echo "${check_pp_C3S/cp1/$remote_user}")
#       if [[ `ssh $remote ls $remote_check_pp_C3S |wc -l` -eq 1 ]]
#       then
               # assign a value with -val selecting a row with -v and a column with -c
#               awk -v r=$LN -v c=$table_column_id_ndays -v val='1' 'BEGIN{FS=OFS=","} NR==r{$c=val} 1' ${DIR_TEMP}/$listfiletocheck > $DIR_TEMP/$listfiletocheck.tmp1
# add 1 second wait to be sure the file has been modified
#               sleep 1

#               mv $DIR_TEMP/$listfiletocheck.tmp1 ${DIR_TEMP}/$listfiletocheck
#       fi
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
          fi
       done #listofcases
  
    done #st

done #remote_mach_list


#now on juno
#find currently running start-dates
local_st_list="`$DIR_UTIL/findjobs.sh -J run.${SPSSystem}|cut -c 14-15|sort -u`"
for st in $local_st_list
do 
   listofcases=`ls -d ${DIR_ARCHIVE}/${SPSSystem}_*${st}_0??`
#   cd $DIR_CASES
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
      LN="$(grep -n "$caso" ${DIR_TEMP}/$listfiletocheck | cut -d: -f1)"
# COMMENTED NOW BECAUSE NOT QC IMPLEMENTED YET
#    if [[ -f $check_pp_C3S ]]
#    then
# assign a value with -val selecting a row with -v and a column with -c
#       awk -v r=$LN -v c=8 -v val='1' 'BEGIN{FS=OFS=","} NR==r{$c=val} 1' ${DIR_TEMP}/$listfiletocheck > $DIR_TEMP/$listfiletocheck.tmp1
# add 1 second wait to be sure the file has been modified
#       sleep 1

#       mv $DIR_TEMP/$listfiletocheck.tmp1 ${DIR_TEMP}/$listfiletocheck
#    else

       CASEROOT=$DIR_CASES/$caso
     # get  check_run_moredays from dictionary
       set +euvx
       . $dictionary     #fixed
       set -euvx
       if [[ -f $check_run_moredays ]]
       then
          for i in `seq 1 $ndone`
          do
# calc position of the ith-column inside csv table
             table_column_id=$(($i + 1))
# assign a value with -val selecting a row with -v and a column with -c
             awk -v r=$LN -v c=$table_column_id -v val='1' 'BEGIN{FS=OFS=","} NR==r{$c=val} 1' ${DIR_TEMP}/$listfiletocheck > $DIR_TEMP/$listfiletocheck.tmp1

# add 1 second wait to be sure the file has been modified
             sleep 1
   
             mv $DIR_TEMP/$listfiletocheck.tmp1 ${DIR_TEMP}/$listfiletocheck

          done
          table_column_id=$table_column_id_ndays
# assign a value with -val selecting a row with -v and a column with -c
          awk -v r=$LN -v c=$table_column_id -v val='1' 'BEGIN{FS=OFS=","} NR==r{$c=val} 1' ${DIR_TEMP}/$listfiletocheck > $DIR_TEMP/$listfiletocheck.tmp1
# add 1 second wait to be sure the file has been modified
          n_complete=$(($n_complete + 1))
          sleep 1

          mv $DIR_TEMP/$listfiletocheck.tmp1 ${DIR_TEMP}/$listfiletocheck
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
   done #listofcases
done #st running


awk -v r=2 -v c=$table_column_id_ndays -v val="$n_complete" 'BEGIN{FS=OFS=","} NR==r{$c=val} 1' ${DIR_TEMP}/$listfiletocheck > $DIR_TEMP/$listfiletocheck.tmp1
sleep 1

mv ${DIR_TEMP}/$listfiletocheck.tmp1 ${DIR_CHECK}/${hindcasts_list}
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
