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
            FVvar_tmp=$WKDIR/${sps}.cam.$ftype.monthly.$var.nc
            cdo -O monmean -selvar,$var $datadir/$sps.cam.$ftype.$yyyy-$st-01-00000.nc $FVvar_tmp
            case $var in
               TREFHT)varout=t2m;;
               TS)varout=sst;;
               PRECT)varout=precip;;
               PSL)varout=mslp;;
               Z500)varout=z500;;
               U200)varout=u200;;
               V200)varout=v200;;
               T850)varout=t850;;
            esac
            FVvar_monthly=$WKDIR/${sps}.cam.$ftype.monthly.$varout.nc
            cdo chname,$var,$varout $FVvar_tmp $FVvar_monthly

     # --- Now interpolate to 1x1 grid
            outputC3S=$WKDIR/${sps}.reg1x1.$varout.nc
#            checkfile=$WKDIR/runtime_regridFV2C3S_${sps}.DONE
            cdo remapbil,$REPOGRID/griddes_C3S.txt $FVvar_monthly $outputC3S
        done
     done
     ncases_proc=$(( $ncases_proc + 1 ))
     if [[ $ncases_proc -eq $nrun ]]
     then
        exit
     fi
done  #end loop on plist
