#!/bin/sh -l
##BSUB -P 0490
##BSUB -J test
##BSUB -e logs/test_%J.err
##BSUB -o logs/test_%J.out
# this script can be run in debug mode but always with submitcommand
# THIS HAS TO BE REVIEWED!!!!!!
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_ncl
set -euvx

#==================================================
export inputFV=$1
caso=$2
export outdirC3S=$3
wkdir=$4
export type=$5 
check_regridC3S_type=$6 
export st=`echo $caso|cut -d '_' -f 2|cut -c 5-6`
export yyyy=`echo $caso|cut -d '_' -f 2|cut -c 1-4`
ens=`echo $caso|cut -d '_' -f 3|cut -c 2,3`

set +euvx
. $DIR_UTIL/descr_ensemble.sh $yyyy
set -euvx
startdate=$yyyy$st
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
export alphaFileName=$REPOGRID/alpha_100m_wind/mean_alpha_${st}.nc
export version=$versionSPS
export real="r"${ens}"i00p00"
export last_term="_"${real}".nc"
export C3Stable="$DIR_POST/cam/C3S_table.txt"
export C3Satts="$DIR_TEMPL/C3S_globalatt.txt"
export GCM_and_version=${GCM_name}-v${version}
export ini_term=cmcc_${GCM_and_version}_${typeofrun}_S${yyyy}${st}0100

#----------------------------------------
# INPUT TO BE REGRIDDED
#----------------------------------------
case $type
in
    h1)  export frq=6hr;;
    h2)  export frq=12hr;;
    h3)  export frq=day;;
    h0)  export frq=fix;;
esac
if [ -f $outdirC3S/regridSE_C3S.ncl_${type}_${real}_ok ] 
then
   if [[ $inputFV -nt $wkdir/regridSE_C3S.ncl_${type}_${real}_ok ]]
   then
      if [[ $debug -eq 0 ]]
      then
# in operational mode rm to recompute
         rm $wkdir/regridSE_C3S.ncl_${type}_${real}_ok
      else
# otherwise just send informative email
         body="$inputFV newer than $wkdir/regridSE_C3S.ncl_${type}_${real}_ok"
         title="[C3S] ${CPSSYS} forecast warning "
         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes" -s $yyyy$st
      fi
   fi    
fi    
# if check file does not exist run the ncl script
if [ ! -f ${check_regridC3S_type}_DONE ] 
then
   export checkfile=${check_regridC3S_type}_DONE
   cp $DIR_POST/cam/regridFV_C3S_template.ncl $wkdir/regridFV_C3S.$type.ncl
   sed -i "s/TYPEIN/$type/g;s/MEMBER/$real/g;s/FRQIN/$frq/g" $wkdir/regridFV_C3S.$type.ncl
   ncl $wkdir/regridFV_C3S.$type.ncl
fi
if [ -f ${check_regridC3S_type}_DONE ]
then
   echo "regridFV_C3S.ncl completed successfully for $type and $real"
else
# if check file does not exist send ERROR email
   touch ${check_regridC3S_type}_ERROR
   body="regridFV_C3S.ncl anomalously exited for start-date ${yyyy}${st}, file type $type and member $real "
   title="[C3S] ${CPSSYS} forecast ERROR"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes" -s $yyyy$st
   exit
fi
echo "$0 completed"
exit 0
