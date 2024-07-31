#!/bin/bash
. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh


function write_help
{
echo "input 1 to just check the list of cases to be removed;
      0 if you want to proceed and remove them"
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

debug=$1
set -euvx
listacasi=""
for i in {1..4}
do
   infile=$DIR_TEMP/list${i}_cases_transferred_`date +%Y%m%d`.txt
   if [[ ! -f $infile ]]
   then
      continue
   fi
   while read line
   do
      echo $line
      listacasi+=" $line"
   done <$infile
done
echo $listacasi
if [[ $debug -eq 1 ]]
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
