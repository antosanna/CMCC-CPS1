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
dbg=$1
set -eu
listacasi=""
infile=$DIR_TEMP/list_cases_transferred_202508.txt
if [[ ! -f $infile ]]
then
     exit
fi
while read line
do
      listacasi+=" $line"
done <$infile
echo $listacasi
if [[ $dbg -eq 1 ]]
then
   exit
fi
LOG_FILE=$DIR_LOG/hindcast/REMOVE_FROM_LEONARDO_FORECAST_TRANSFERRED_`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1

set -euvx
echo "GOING TO REMOVE THE FOLLOWING"
echo $listacasi
yyyy=`date +%Y`
st=`date +%m`
if [[ `ls ${DIR_ARCHIVE}/sps4_${yyyy}${st}_0??.transfer_from_Leonardo_DONE |wc -l` -ge 50 ]] 
then
  for ens in `seq -w 001 054` ; do
    caso=sps4_${yyyy}${st}_${ens}
    if [[ -d ${DIR_ARCHIVE}/$caso ]]; then
        echo $caso   
        chmod -R u+wrx ${DIR_ARCHIVE}/$caso
        rm -r ${DIR_ARCHIVE}/$caso/*
#    else
#       echo "$caso already removed"
#       exit
     fi
     if [[ -d ${WORK_CPS}/$caso ]]
     then
         rm -r ${WORK_CPS}/$caso
     fi
  done
fi
echo "Succesfully removed cases for forecast $yyyy$st"
