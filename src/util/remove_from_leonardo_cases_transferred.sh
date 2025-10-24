#!/bin/sh -l
. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh


function write_help
{
echo "first input 1 to just check the list of cases to be removed;
                  0 if you want to proceed and remove them
      second input (optional): number of days to check back starting from today (default=1, i.e. yesterday and today)"
}

if [[ -z "$1" ]]
then
   write_help 
   exit
fi
if [[ "$1" == "-h" ]]
then
   write_help 
   exit 
fi
LOG_FILE=$DIR_LOG/hindcast/REMOVE_FROM_LEONARDO_CASES_TRANSFERRED_`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1

dbg=$1
set -euvx
listacasi=""

n_daysback=${2:-1}
today=`date +%Y%m%d`
for dd in `seq 0 ${n_daysback}` 
do
   data=$(date -d "${today} - ${dd} days" +'%Y%m%d')
   for i in {1..6} #in principle up to 6 transfer in parallel
   do
      n_infiles=`ls $DIR_TEMP/list${i}_cases_transferred_${data}.*txt|wc -l`
      if [[ ${n_infiles} -eq 0 ]]
      then
         continue
      fi
      infiles=`ls $DIR_TEMP/list${i}_cases_transferred_${data}.*txt`
      for ff in $infiles
      do
         if [[ ! -f $ff ]]
         then
            continue
         fi
         while read line
         do
            echo $line
            listacasi+=" $line"
         done <$ff
      done
   done
done
echo $listacasi
if [[ $dbg -eq 1 ]]
then
   exit
fi

for caso in $listacasi ; do

 if [[ -f ${DIR_ARCHIVE}/$caso.transfer_from_Leonardo_DONE ]] ; then
    if [[ ! -z `ls -A ${DIR_ARCHIVE}/$caso` ]]; then
        echo $caso   
        rm -r ${DIR_ARCHIVE}/$caso/*
#    else
#       echo "$caso already removed"
#       exit
    fi
    if [[ -d ${WORK_CPS}/$caso ]]
    then
       rm -r ${WORK_CPS}/$caso
    fi
  fi

done
echo "Succesfully removed $listacasi"
