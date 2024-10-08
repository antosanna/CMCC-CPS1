#!/bin/sh -l
#BSUB -P 0490
#BSUB -J test
#BSUB -e logs/test_%J.err
#BSUB -o logs/test_%J.out
# this script can be run in dbg mode but always with submitcommand
# THIS IHAS TO BE REVIEWED!!!!!!
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_cdo
. $DIR_UTIL/load_nco
. $DIR_UTIL/load_ncl
set -euvx
here=$PWD
#dbg=${7:-0}    #new argument to allow test in dbg mode
dbg=1
#

if [ $dbg -eq 1 ] 
then
#==================================================
# USER DEFINED SECTION
#==================================================
   caso=cps_complete_test_output
   export ic="atm=test,lnd=test,ocn=test"
   export outdirC3S=$SCRATCHDIR/output_test_C3S
   mkdir -p $outdirC3S
   inputdirCAM=/work/csp/$USER/CESM2/archive/cps_complete_test_output/atm/hist/
   inputdirCICE=/work/csp/$USER/CESM2/archive/cps_complete_test_output/ice/hist
   running=0 # 0 if running; 1 if off-line
   export st=02
   export yyyy=2000
   ens=001
#==================================================
# END USER DEFINED SECTION
#==================================================
else
#==================================================
# IN OPERATIONAL MODE RECEIVE INPUTS FROM PARENT SCRIPT
#==================================================
   caso=$1
   export ic=$2
   export outdirC3S=$3
   inputdirCAM=$4
   inputdirCICE=$5
   running=$6 # 0 if running; 1 if off-line
   export st=`echo $caso|cut -d '_' -f 2|cut -c 5-6`
   export yyyy=`echo $caso|cut -d '_' -f 2|cut -c 1-4`
   ens=`echo $caso|cut -d '_' -f 3|cut -c 2,3`
fi

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
REPOTMP=$SCRATCHDIR/tmp
#export srcGridName=$REPOGRID/srcGrd_FV.nc
#export dstGridName=$REPOGRID/dstGrd_${outputgrid}.nc
#export wgtFileName=$REPOGRID/CAMFV05_2_${outputgrid}_C3S.nc
#export wgtFileNameCons=$REPOGRID/CAMFV05_2_${outputgrid}_conserve_C3S.nc
export srcGridName=$REPOTMP/srcGrd_FV.nc
export dstGridName=$REPOTMP/dstGrd_${outputgrid}.nc
export wgtFileName=$REPOTMP/CAMFV05_2_${outputgrid}_C3S.nc
export wgtFileNameCons=$REPOTMP/CAMFV05_2_${outputgrid}_conserve_C3S.nc
export lsmFileName=$REPOGRID/lsm_SPS3.5_cam_h1_reg1x1_0.5_359.5.nc
export version=$versionSPS
export real="r"${ens}"i00p00"
export last_term="_"${real}".nc"
export C3Stable="$DIR_TEMPL/C3S_table.txt"
#export C3Stable="$here/C3S_table.txt"
export C3Satts="$DIR_TEMPL/C3S_globalatt.txt"
export fixsimdays

#----------------------------------------
# INPUT TO BE REGRIDDED
#----------------------------------------
for type in h3 #h0 h1 h2 h3 
do
   export type=$type
   export inputFV=$inputdirCAM/$caso.cam.${type}.$yyyy-$st-01-00000.nc
   case $type
   in
       h1)  export frq=6hr;outxday=4;;
       h2)  export frq=12hr;outxday=2;;
       h3)  export frq=day;outxday=1;;
   esac
# cat file containing all the forecast timesteps generated by lt_archive_C3S_moredays.sh
#
# check file for correct temination of ncl script.
# in operational mode it is mandatory that checkfile is older than its output file
   if [ -f $outdirC3S/regridSE_C3S.ncl_${type}_${real}_ok ] 
   then
      cd $inputdirCAM
      if [[ $inputFV -nt $outdirC3S/regridSE_C3S.ncl_${type}_${real}_ok ]]
      then
         if [[ $dbg -eq 0 ]]
         then
# in operational mode rm to recompute
            rm $outdirC3S/regridSE_C3S.ncl_${type}_${real}_ok
         else
# otherwise just send informative email
            body="$inputFV newer than $outdirC3S/regridSE_C3S.ncl_${type}_${real}_ok"
            title="[C3S] ${SPSSYS} forecast warning "
            ${DIR_SPS}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
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
      title="[C3S] ${SPSSYS} forecast ERROR"
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
      exit
   fi
done
exit
#-------------------------------------------------------------
# Go to output dir for C3S vars
#-------------------------------------------------------------
cd $outdirC3S
#-------------------------------------------------------------
# read all cam variables from $C3Stable
#-------------------------------------------------------------
{
read 
while IFS=, read -r flname C3S dim lname sname units freq type realm addfact coord cell varflg
do
   varC3S+=" $C3S"
done } < $C3Stable
for var in $varC3S
do
#-------------------------------------------------------------
# now check that all required vars but rsdt have been produced
#-------------------------------------------------------------
    if [ ${var} != "rsdt" ]
    then
       if [ ! -f *${var}_*${real}.nc ]
       then
           body="$var C3S from CAM missing for case $caso. Exiting $DIR_POST/cam/regridSEne60_C3S.sh "
           title="[C3S] ${SPSSYS} forecast ERROR"
           ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
           exit
       fi  
    fi  
done
if [ ! -f $outdirC3S/interp_cice2C3S_through_nemo.ncl_${real}_ok ] || [[ $dbg -eq 0 ]]
then
#-------------------------------------------------------------
# compute C3S var from CICE
#-------------------------------------------------------------
   $DIR_POST/cice/interp_cice2C3S.sh $caso "$ic" $outdirC3S $inputdirCICE $running
fi
# NEW 202103 !!!!!! -
# if check file for cice vars does not exist send ERROR email
if [ ! -f $outdirC3S/interp_cice2C3S_through_nemo.ncl_${real}_ok ]
then
  body="ERROR in standardization of CICE file for $caso case. $DIR_POST/cice/interp_cice2C3S.sh "
  title="[C3S] ${SPSSYS} forecast ERROR "
  ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
  exit
fi
check_cam_C3SDONE=$outdirC3S/${caso}_cam_C3SDONE
#-------------------------------------------------------------
# Compute rdst (check for checkfile inside the script)
#-------------------------------------------------------------
$DIR_POST/cam/compute_daily_rsdt.sh $yyyy $st $ens $outdirC3S
stat=$?
if [ $stat -ne 0 ]
then
   body="ERROR in $DIR_POST/cam/compute_daily_rsdt.sh for $caso case launched by $DIR_POST/cam/regridSEne60_C3S.sh "
   title="[C3S] ${SPSSYS} forecast ERROR "
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
   exit 1
fi

#-------------------------------------------------------------
# CHECK TIMESTEP AND IN CASE FIX IT
#-------------------------------------------------------------
checkfix_timesteps=$outdirC3S/fix_timesteps_C3S_${startdate}_${ens}_ok
$DIR_C3S/fix_timesteps_C3S_1member.sh $startdate $ens $checkfix_timesteps $outdirC3S

touch $check_cam_C3SDONE


cd $outdirC3S   #can be redundant
member=$ens
allC3S=`ls *${real}.nc|wc -l`
#-------------------------------------------------------------
# IF ALL VARS HAVE BEEN COMPUTED QUALITY-CHECK
#-------------------------------------------------------------
mkdir -p $DIR_CASES/$caso/logs/
checkfile=$DIR_CASES/$caso/logs/qa_started_${startdate}_0${member}_ok
# if not already launched
if [ $allC3S -eq $nfieldsC3S ] && [ ! -f $checkfile ]
then
   ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -M 3000 -t "24" -r $sla_serialID -S qos_resv -j checker_and_archive_${caso} -l ${DIR_LOG}/$typeofrun/${startdate} -d ${DIR_POST}/C3S_standard -s checker_and_archive.sh -i "$member $outdirC3S $startdate $caso"
fi
echo "$0 completed"
exit 0
