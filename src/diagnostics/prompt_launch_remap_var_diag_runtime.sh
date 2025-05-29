#!/bin/sh -l

. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. $DIR_UTIL/load_cdo
. $DIR_UTIL/load_nco

set -evxu


yyyy=$1
st=$2
nrun=$3
scrdir=$4
nmf=$5
WKDIR=$6
inputfile=$7
dbg=$8
invarlist="$9"

set +euvx
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -euvx
mkdir -p $WKDIR 

resty=`date -d "${yyyy}${st}01 + $nmf months" +%Y`
restm=`date -d "${yyyy}${st}01 + $nmf months" +%m`
while read -r line;
do
   plist+=" $line"
done < $inputfile
count=`echo $plist |wc -w`
if [ $count -lt $nrun ] 
then 
     echo " you cannot perform this analysis cause the number of ensemble members is less than " $nrun
     exit    
fi
#
  
list4cdo=`echo $invarlist|sed -e "s/ /,/g"`
ncases_proc=0
for sps in $plist 
do
     datadir="$DIR_ARCHIVE/$sps/atm/hist/"
     lastrestdir=`ls $DIR_ARCHIVE/$sps/rest/|tail -1`
     lastyy=`echo $lastrestdir|cut -c 1-4`
     lastmm=`echo $lastrestdir|cut -c 6-7`
# this assures that member $sps has completed month $currmon
     if [[ $lastyy$lastmm -lt $resty$restm ]]  
     then
        continue 1 # meaning that the job is still running and 
                   # the reforecast is not complete
     fi 

#
# AT THE MOMENT h1 IS ENOUGH BUT YOU COULD ADD h3
     for ftype in h1  #h3
     do
        for var in $invarlist
        do
            $DIR_DIAG/remap_var_diag_runtime.sh $yyyy $st $sps $var $ftype $datadir $WKDIR &
        done
     done
     ncases_proc=$(( $ncases_proc + 1 ))
     if [[ $ncases_proc -eq $nrun ]]
     then
        exit
     fi
done  #end loop on plist
