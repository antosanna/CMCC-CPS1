#!/bin/sh -l 

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_nco
set -evxu

caso=EXPNAME
ic="DUMMYIC"

st=`./xmlquery RUN_STARTDATE|cut -d ':' -f2|sed 's/ //'|cut -d '-' -f2`
yyyy=`./xmlquery RUN_STARTDATE|cut -d ':' -f2|sed 's/ //'|cut -d '-' -f1`

#load_nco after xmlquery to avoid conflict with conda environmens on leonardo
set +euvx
   . ${DIR_UTIL}/descr_ensemble.sh $yyyy
   . ${DIR_UTIL}/load_nco
set -euvx
#
startdate=$yyyy$st
ens=`echo $caso|cut -d '_' -f 3 `
member=`echo $ens|cut -c2,3` 

HEALED_DIR=$HEALED_DIR_ROOT/$caso
#HEALED_DIR_ROOT=/work/cmcc/cp1/CPS/CMCC-CPS1/fixed_from_spikes/
# SECTION FORECAST TO BE TESTED
set +euvx
. $dictionary
set -euvx

##20241002 - TEMPORARY COMMENTED WAITING FOR NOTIFICATE

#if [ "$typeofrun" == "forecast" ]
#then
#   mkdir -p $DIR_LOG/$typeofrun/$yyyy$st
##get   check_endrun check_notificate check_submitnotificate from dictionary
#   touch $fileendrun
#   # dal 50 al 54esimo il primo che arriva entra qua
#   cntforecastend=$(ls ${check_endrun}_* | wc -l)
#   if [ $cntforecastend -ge $nrunC3Sfore ] 
#   then
      
#      # qui va il 4^ notificate
#      if [ ! -f $check_notificate ]; then
## get check_submitnotificate from dictionary
#         touch $check_submitnotificate
#         # submit notificate 4 - FINE JOBS PARALLELI
#         input="`whoami` 0 $yyyy $st 1 4"
#         ${DIR_UTIL}/submitcommand.sh -r $sla_serialID -S qos_resv -q $serialq_s -j notificate${startdate}_4th -l ${DIR_LOG}/$typeofrun/$yyyy$st -d ${DIR_UTIL} -s notificate.sh -i "$input"
#         touch $check_notificate
#
#      fi
#
#   fi
#fi
# END OF FORECAST SECTION


# directory creation
outdirC3S=${WORK_C3S}/$yyyy$st/
mkdir -p $outdirC3S

# get   check_oceregrid from dictionary
mkdir -p $SCRATCHDIR/regrid_C3S/$caso/NEMO
if [[ ! -f $check_oceregrid ]]
then
    #logdir as input to manage remote vs local cases (online vs offline postproc)
    ${DIR_UTIL}/submitcommand.sh -m $machine -q $parallelq_m -S qos_resv -M 7500 -j interp_ORCA2_1X1_gridT2C3S_${caso} -l $DIR_CASES/$caso/logs/ -d ${DIR_CASES}/$caso -s interp_ORCA2_1X1_gridT2C3S_${caso}.sh -i "$DIR_CASES/$caso/logs"

fi
# get   check_iceregrid from dictionary
mkdir -p $SCRATCHDIR/regrid_C3S/$caso/CICE
if [ ! -f $check_iceregrid ]
then
    ${DIR_UTIL}/submitcommand.sh -m $machine -q $parallelq_s -S qos_resv -M 4000 -j interp_cice2C3S_${caso} -l $DIR_CASES/$caso/logs/ -d ${DIR_CASES}/$caso -s interp_cice2C3S_${caso}.sh 
fi 

#***********************************************************************
# Standardization for CLM 
#***********************************************************************
wkdir_clm=$SCRATCHDIR/regrid_C3S/$caso/CLM
mkdir -p ${wkdir_clm}
# get check_postclm  from dictionary

if [[ ! -f $check_all_postclm ]]
then
  
   cd ${wkdir_clm}
   filetyp="h1 h3"
   for ft in $filetyp ; do

      case $ft in
          h1 ) mult=1 ; req_mem=12000 ;; # for land h1 is daily, multiplier=1
          h3 ) mult=1 ; req_mem=1000 ;; # for land h3 is daily, multiplier=1
      esac
      flag_for_type=${check_postclm_type}_${ft}_DONE
      finalfile_clm=$DIR_ARCHIVE/$caso/lnd/hist/$caso.clm2.$ft.$yyyy-$st.zip.nc
      if [[ ! -f $finalfile_clm ]]
      then
            input="$caso $ft ${wkdir_clm} ${finalfile_clm} ${flag_for_type} $ic $mult"
            # ADD the reservation for serial !!!
            ${DIR_UTIL}/submitcommand.sh -m $machine -q $parallelq_m -S qos_resv -M 5000 -j create_clm_files_${ft}_${caso} -l ${DIR_CASES}/$caso/logs/ -d ${DIR_POST}/clm -s create_clm_files.sh -i "$input"

           echo "start of postpc_clm "`date`
           input="${finalfile_clm} $ens $startdate $outdirC3S $caso ${flag_for_type} ${wkdir_clm} $ic $ft"  
           # ADD the reservation for serial !!!
           ${DIR_UTIL}/submitcommand.sh -m $machine -q $parallelq_l -M ${req_mem} -S qos_resv -p create_clm_files_${ft}_${caso} -j postpc_clm_${ft}_${caso} -l $DIR_CASES/$caso/logs/ -d ${DIR_POST}/clm -s postpc_clm.sh -i "$input"
      else
           echo "start of postpc_clm "`date`
           input="${finalfile_clm} $ens $startdate $outdirC3S $caso ${flag_for_type} ${wkdir_clm} $ic $ft"
           # ADD the reservation for serial !!!
           ${DIR_UTIL}/submitcommand.sh -m $machine -q $parallelq_l -M ${req_mem} -S qos_resv -j postpc_clm_${ft}_${caso} -l $DIR_CASES/$caso/logs/ -d ${DIR_POST}/clm -s postpc_clm.sh -i "$input"
      fi
    done 
 
fi


#***********************************************************************
# Cam files archiving
#***********************************************************************
# Standardization for CAM 
#***********************************************************************
wkdir_cam=$SCRATCHDIR/regrid_C3S/$caso/CAM
mkdir -p ${wkdir_cam}
#get check_all_camC3S_done from dictionary
if [[ ! -f $check_all_camC3S_done ]]
then

   filetyp="h0 h1 h2 h3"
   for ft in $filetyp
   do  
   #get check_regridC3S_type from dictionary
      if [[ -f ${check_regridC3S_type}_${ft}_DONE ]]
      then
#   # meaning that preproc files have been done by create_cam_files.sh
#   # and regridded by regridFV_C3S.sh
         continue
      fi
      finalfile=$DIR_ARCHIVE/$caso/atm/hist/$caso.cam.$ft.$yyyy-$st.zip.nc
      if [[ ! -f $finalfile ]]
      then
         input="$caso $ft ${wkdir_cam} $finalfile $ic"
             # ADD the reservation for serial !!!
         ${DIR_UTIL}/submitcommand.sh -m $machine -q $parallelq_m -S qos_resv -M 4000 -j create_cam_files_${ft}_${caso} -l $DIR_CASES/$caso/logs/ -d ${DIR_POST}/cam -s create_cam_files.sh -i "$input"
      fi
   done
   while [[ ! -f ${check_merge_cam_files}_h1 ]] || [[ ! -f ${check_merge_cam_files}_h2 ]] || [[ ! -f ${check_merge_cam_files}_h3 ]]
   do
      sleep 600
   done
             #now fix for spikes on $HEALED_DIR
             # we want to archive the DMO with spikes
             # this is an iterative procedure that might requires a few cycles (up to 3 I guess)
   input="$caso $HEALED_DIR"
   ${DIR_UTIL}/submitcommand.sh -m $machine -q $parallelq_m -S qos_resv -M 19000 -p create_cam_files_h3_${caso} -j fix_spikes_DMO_single_member_h3_${caso} -l $DIR_CASES/$caso/logs/ -d ${DIR_POST}/cam -s fix_spikes_DMO_single_member.sh -i "$input"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "submitted" -t "fix_spikes_DMO_single_member_h3_${caso} submitted" -r "only" -s $yyyy$st -E $ens
   while [[ ! -f $HEALED_DIR/${caso}.cam.h1.DONE ]] || [[ ! -f $HEALED_DIR/${caso}.cam.h2.DONE ]] || [[ ! -f $HEALED_DIR/${caso}.cam.h3.DONE ]]
   do
      sleep 600
   done
   ${DIR_POST}/cam/check_minima_TREFMNAV_TREFHT.sh $caso $HEALED_DIR
# TREATMENT COMPLETED
   touch $DIR_CASES/$caso/logs/spike_treatment_${caso}_DONE
# h2 is the file requiring more time to be postprocessed
   for ft in h0 h1 h3 h2
   do

      case $ft in
          h1)req_mem=9000;;
          h2)req_mem=4000;;
          h3)req_mem=1500;;
      esac
      finalfile=$HEALED_DIR/$caso.cam.$ft.$yyyy-$st.zip.nc
      if [[ $ft == "h0" ]]
      then
          finalfile=$DIR_ARCHIVE/$caso/atm/hist/$caso.cam.$ft.$yyyy-$st.zip.nc
      fi
# $HEALED_DIR/${caso}.cam.$ft.DONE is defined in poisson_daily_values.sh
      input="$finalfile $caso $outdirC3S ${wkdir_cam} $ft $ic"
             # ADD the reservation for serial !!!
      ${DIR_UTIL}/submitcommand.sh -m $machine -q $parallelq_m -S qos_resv  -M ${req_mem} -j regrid_cam_${ft}_${caso} -l $DIR_CASES/$caso/logs/ -d ${DIR_POST}/cam -s regridFV_C3S.sh -i "$input"

   done
#  now apply fix for isobaric level T on ft=h2 
   WKDIR=$SCRATCHDIR/extrapT/${caso}
   mkdir -p $WKDIR
   checkfileextrap=$DIR_CASES/$caso/logs/${yyyy}${st}_extrapT_DONE
   inputextrap="$caso $checkfileextrap $WKDIR"
   req_mem=8000
   ${DIR_UTIL}/submitcommand.sh -m $machine -q $parallelq_m -S qos_resv  -M ${req_mem} -p regrid_cam_h2_${caso} -j extrapT_SPS4_${caso} -l $DIR_CASES/$caso/logs/ -d ${DIR_POST}/cam -s extrapT_SPS4.sh -i "$inputextrap"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "submitted" -t "extrapT_SPS4_${caso} submitted" -r "only" -s $yyyy$st -E $ens
   while `true`
   do
      if [[ -f ${checkfileextrap} ]]
      then
         break
      fi
      sleep 120
   done
   while `true`
   do
      if [[ `ls ${check_regridC3S_type}_h?_DONE|wc -l` -eq 4 ]]
      then
         touch $check_all_camC3S_done
         break
      fi
      sleep 60
   done

fi # if on $check_all_camC3S_done 

while `true`
do
    if [[ `ls ${check_postclm_type}_??_DONE |wc -l` -eq 2 ]]
    then
       touch ${check_all_postclm}
       break
    fi  
    sleep 60
done   

while `true`
do
   if [[ -f $check_all_postclm ]] && [[ -f $check_iceregrid ]] && [[ -f $check_oceregrid ]] && [[ -f $check_all_camC3S_done ]]
   then
      break
   fi
   sleep 60
done
touch $check_pp_C3S
real="r"${member}"i00p00"
#this should be redundant after $check_pp_C3S but we keep it
allC3S=`ls $outdirC3S/*${real}.nc|wc -l`
if [[ $allC3S -eq $nfieldsC3S ]] 
then
   #MUST BE ON A SERIAL to write c3s daily files on /data
   ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -M 3000 -S qos_resv -j C3Schecker_${caso} -l ${DIR_LOG}/$typeofrun/${startdate} -d ${DIR_POST}/C3S_standard -s C3Schecker.sh -i "$member $outdirC3S $startdate"
else
   if [[ $allC3S -eq $(($nfieldsC3S - 1 )) ]] && [[ -f $check_no_SOLIN ]]
   then
      body="$caso exited before C3Schecker.sh in postproc_C3S.sh because the case $caso does not contain SOLIN. Must be created"
      title="[CPS1] ERROR! postproc_C3S.sh exiting before no SOLIN in $caso"
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "only" -s $yyyy$st -E $ens
      exit 2
   else
      body="$caso exited before C3Schecker.sh in postproc_C3S.sh because the number of postprocessed files is $allC3S instead of required $nfieldsC3S"
      title="[CPS1] ERROR! $caso exiting before $DIR_C3S/C3Schecker.sh"
      ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "only" -s $yyyy$st -E $ens
      exit 1
   fi
fi
#***********************************************************************
# checkout the list
#***********************************************************************
# NOT SURE WE NEED IT
#cd $DIR_CASES/$caso/Tools/
#if [ `whoami` == ${operational_user} ]
#then
#   ./checklist_run.sh $jobIDdummy True
#fi
#***********************************************************************
# Remove $WORK_CPS/$caso
#***********************************************************************
if [ -d $WORK_CPS/$caso ]
then
  cd $WORK_CPS/$caso
  rm -rf run
  rm -rf bld
  cd $WORK_CPS
  rmdir $caso
fi
for realm in clm2 cam hydros
do
   case $realm in
      clm2)listatypes="h0 h1 h2 h3";dirname=lnd;;
      cam)listatypes="h0 h1 h2 h3 h4";dirname=atm;;
      hydros)listatypes="h0";dirname=rof;;
   esac
   for ft in $listatypes
   do
      if [[ $ft == "h0" ]]
      then
         suff=".nc"
      else
         suff="-01-00000.nc"
      fi
      n_zip=`ls $DIR_ARCHIVE/$caso/$dirname/hist/$caso.$realm.$ft.*zip.nc|wc -l`
      if [[ $n_zip -ne 0 ]]
      then
         listzip=`ls $DIR_ARCHIVE/$caso/$dirname/hist/$caso.$realm.$ft.*zip.nc`
         for ff in $listzip
         do
            rootf=`echo $ff|rev|cut -d '.' -f3-|rev`
            if [[ -f $rootf$suff ]]
            then
               rm $rootf$suff
               echo "$rootf$suff removed"
            fi
         done
      else
         n=`ls $DIR_ARCHIVE/$caso/$dirname/hist/$caso.$realm.$ft.*[0-9].nc|wc -l`
         if [[ $n -ne 0 ]]
         then
            list=`ls $DIR_ARCHIVE/$caso/$dirname/hist/$caso.$realm.$ft.*[0-9].nc`
            for ff in $list
            do
               finalf=`echo "${ff/$suff/.zip.nc}"`
               echo "compress $ff $finalf"
               $compress $ff $finalf
               rm $ff
               echo "$ff removed"
            done
         fi
      fi
   done   #type
done  #realm
if [[ `ls $DIR_ARCHIVE/$caso/ocn/hist/${caso}_1d_????????_????????_grid_T_0???.nc |wc -l` -ge 1 ]] ; then
  rm $DIR_ARCHIVE/$caso/ocn/hist/${caso}_1d_????????_????????_grid_T_0???.nc
fi
if [[ `ls  $DIR_ARCHIVE/$caso/ocn/hist/${caso}_1d_????????_????????_grid_EquT_T_0???.nc |wc -l` -ge 1 ]] ; then
   rm $DIR_ARCHIVE/$caso/ocn/hist/${caso}_1d_????????_????????_grid_EquT_T_0???.nc
fi
if [[ `ls $DIR_ARCHIVE/$caso/rest/????-??-01-00000/ic_for_${caso}_00000001_restart.nc |wc -l` -ge 1 ]] ; then
   rm $DIR_ARCHIVE/$caso/rest/????-??-01-00000/ic_for_${caso}_00000001_restart.nc
fi
if [[ -d $DIR_TEMP/$caso ]]
then
   rm -rf $DIR_TEMP/$caso
fi
chmod u-w -R $DIR_ARCHIVE/$caso/
#
for realm in CAM CLM NEMO CICE
do
   if [[ `ls $SCRATCHDIR/regrid_C3S/$caso/$realm/*nc |wc -l` -gt 0 ]]
   then
      rm -rf $SCRATCHDIR/regrid_C3S/$caso/$realm/*nc
   fi  
done
#
if [[ -d $SCRATCHDIR/extrapT/${caso} ]]
then
   rm -rf $SCRATCHDIR/extrapT/${caso}
fi
if [[ -d $HEALED_DIR ]]
then
   rm -rf $HEALED_DIR 
fi


echo "Done."

exit 0

