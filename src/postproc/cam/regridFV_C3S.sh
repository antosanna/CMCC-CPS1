#!/bin/sh -l
#BSUB -P 0490
#BSUB -J test
#BSUB -e logs/test_%J.err
#BSUB -o logs/test_%J.out
# this script can be run in debug mode but always with submitcommand
# THIS IHAS TO BE REVIEWED!!!!!!
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_ncl
set -euvx

#==================================================
ft=$1
caso=$2
export outdirC3S=$3
inputdirCAM=$4
running=$5 # 0 if running; 1 if off-line
export st=`echo $caso|cut -d '_' -f 2|cut -c 5-6`
export yyyy=`echo $caso|cut -d '_' -f 2|cut -c 1-4`
ens=`echo $caso|cut -d '_' -f 3|cut -c 2,3`

set +euvx
. $DIR_UTIL/descr_ensemble.sh $yyyy
set -euvx
export ndaysreq=$fixsimdays
startdate=$yyyy$st
# These variables are required by ncl script regrid from SE to reg1x1
export fore_type=$typeofrun
export yyyytoday=`date +%Y`
export mmtoday=`date +%m`
export ddtoday=`date +%d`
export Htoday=`date +%H`
export Mtoday=`date +%M`
export Stoday=`date +%S`
export outputgrid="reg1x1"
export srcGridName=$REPOGRID/srcGrd_FV.nc
export dstGridName=$REPOGRID/dstGrd_${outputgrid}.nc
export wgtFileName=$REPOGRID/CAMFV05_2_${outputgrid}_bilinear_C3S.nc
export wgtFileNameCons=$REPOGRID/CAMFV05_2_${outputgrid}_conserve_C3S.nc
export lsmFileName=$REPOGRID/SPS4_C3S_LSM.nc
export version=$versionSPS
export real="r"${ens}"i00p00"
export last_term="_"${real}".nc"
export C3Stable="$DIR_POST/cam/C3S_table.txt"
export C3Satts="$DIR_TEMPL/C3S_globalatt.txt"
export fixsimdays

#----------------------------------------
# INPUT TO BE REGRIDDED
#----------------------------------------
export type=$ft
export inputFV=$inputdirCAM/$caso.cam.${type}.$yyyy-$st-01-00000.nc
case $type
in
    h1)  export frq=6hr;outxday=4;;
    h2)  export frq=12hr;outxday=2;;
    h3)  export frq=day;outxday=1;;
esac
if [ -f $outdirC3S/regridSE_C3S.ncl_${type}_${real}_ok ] 
then
   cd $inputdirCAM
   if [[ $inputFV -nt $outdirC3S/regridSE_C3S.ncl_${type}_${real}_ok ]]
   then
      if [[ $debug -eq 0 ]]
      then
# in operational mode rm to recompute
         rm $outdirC3S/regridSE_C3S.ncl_${type}_${real}_ok
      else
# otherwise just send informative email
         body="$inputFV newer than $outdirC3S/regridSE_C3S.ncl_${type}_${real}_ok"
         title="[C3S] ${CPSSYS} forecast warning "
         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
      fi
   fi    
fi    
# if check file does not exist run the ncl script
if [ ! -f $outdirC3S/regridFV_C3S.ncl_${type}_${real}_ok ] 
then
      ncl $DIR_POST/cam/regridFV_C3S.ncl
fi
if [ -f $outdirC3S/regridFV_C3S.ncl_${type}_${real}_ok ]
then
      echo "regridFV_C3S.ncl completed successfully for $type and $real"
else
# if check file does not exist send ERROR email
      touch $outdirC3S/regridFV_C3S.ncl_${type}_${real}_error
      body="regridFV_C3S.ncl anomalously exited for start-date ${yyyy}${st}, file type $type and member $real "
      title="[C3S] ${CPSSYS} forecast ERROR"
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
      exit
fi
echo "$0 completed"
exit 0
