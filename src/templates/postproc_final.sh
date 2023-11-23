#!/bin/sh -l 

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. $DIR_UTIL/load_nco
. $DIR_UTIL/load_cdo

set -evxu

checkfile_postproc_final=$1
caso=EXPNAME
ic="DUMMYIC"

st=`./xmlquery RUN_STARTDATE|cut -d ':' -f2|sed 's/ //'|cut -d '-' -f2`
yyyy=`./xmlquery RUN_STARTDATE|cut -d ':' -f2|sed 's/ //'|cut -d '-' -f1`
set +euvx
   . ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -euvx
#
member=`echo $caso|cut -d '_' -f 3|cut -c 2-3`
startdate=$yyyy$st
ppp=`echo $caso|cut -d '_' -f 3 `

# SECTION FORECAST TO BE TESTED
if [ "$typeofrun" == "forecast" ]
then
   mkdir -p $DIR_LOG/$typeofrun/$yyyy$st
   fileendrun=$DIR_LOG/$typeofrun/$yyyy$st/${caso}_forecast_end
   filenotificate=$DIR_LOG/$typeofrun/$yyyy$st/notificate_fine_forecast
   touch $fileendrun
   # dal 50 al 54esimo il primo che arriva entra qua
   cntforecastend=$(ls $DIR_LOG/$typeofrun/$yyyy$st/*_forecast_end | wc -l)
   if [ $cntforecastend -ge $nrunC3Sfore ] 
   then
      
      # qui va il 4^ notificate
      if [ ! -f $filenotificate ]; then
         touch $DIR_LOG/$typeofrun/$yyyy$st/${caso}_submittingnotificate
         # submit notificate 4 - FINE JOBS PARALLELI
         input="`whoami` 0 $yyyy $st 1 4"
         ${DIR_UTIL}/submitcommand.sh -r $sla_serialID -S qos_resv -q $serialq_s -j notificate${startdate}_4th -l ${DIR_LOG}/$typeofrun/$yyyy$st -d ${DIR_UTIL} -s notificate.sh -i "$input"
         touch $filenotificate

      fi

   fi
fi
# END OF FORECAST SECTION

checkfile_qa=`grep check_qa $dictionary|cut -d '=' -f2`
# directory creation
outdirC3S=${WORK_C3S}/$yyyy$st/
mkdir -p $outdirC3S

#***********************************************************************
# Standardization for CLM 
#***********************************************************************
wkdir_clm=$SCRATCHDIR/regrid_C3S/CLM/$caso
mkdir -p ${wkdir_clm}
checkfile_clm=`grep check_clm $dictionary|cut -d '=' -f2`

if [[ ! -f $checkfile_clm ]]
then
  
   cd ${wkdir_clm}
   ft="h1"
   case $ft in
       h1 ) mult=1 ;; # for land h1 is daily, multiplier=1
   esac
   finalfile_clm=$DIR_ARCHIVE/$caso/lnd/hist/$caso.clm2.$ft.$yyyy-$st.zip.nc
   if [[ ! -f $finalfile_clm ]]
   then

        input="$caso $ft $yyyy $st ${wkdir_clm} ${finalfile_clm} $checkfile_clm"
        # ADD the reservation for serial !!!
        ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -S qos_resv -t "24" -M 55000 -j create_clm_files_${ft}_${caso} -l ${DIR_CASES}/$caso/logs/ -d ${DIR_POST}/clm -s create_clm_files.sh -i "$input"
        

        echo "start of postpc_clm "`date`
        input="${finalfile_clm} $ppp $startdate $outdirC3S $caso $checkfile_clm $checkfile_qa ${wkdir_clm} 0"  #0 means done while running (1 if from archive)
        # ADD the reservation for serial !!!
        ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -M 6500 -S qos_resv -t "24" -p create_clm_files_${ft}_${caso} -j postpc_clm_${caso} -l $DIR_CASES/$caso/logs/ -d ${DIR_POST}/clm -s postpc_clm.sh -i "$input"

   else
    # meaning that preproc files have been done by create_clm_files.sh
    # so submit without dependency
        
        echo "start of postpc_clm "`date`
        input="${finalfile_clm} $ppp $startdate $outdirC3S $caso $checkfile_clm $checkfile_qa ${wkdir_clm} 0"  #0 means done while running (1 if from archive)
        # ADD the reservation for serial !!!
        ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -M 6500 -S qos_resv -t "24" -j postpc_clm_${caso} -l $DIR_CASES/$caso/logs/ -d ${DIR_POST}/clm -s postpc_clm.sh -i "$input"
   fi
fi


#***********************************************************************
# Cam files archiving
#***********************************************************************
# Standardization for CAM 
#***********************************************************************
wkdir_cam=$SCRATCHDIR/regrid_C3S/CAM/$caso
mkdir -p ${wkdir_cam}
checkfile_all_camC3S_done=`grep check_all_camC3S_done $dictionary|cut -d '=' -f2`
filetyp="h1 h2 h3"
for ft in $filetyp
do
   checkfile_regridC3S_type=`grep check_regridC3S_type $dictionary|cut -d '=' -f2`
   if [[ -f ${checkfile_regridC3S_type}_${ft}_DONE ]]
   then
# meaning that preproc files have been done by create_cam_files.sh
# and regridded by regridFV_C3S.sh
      continue
   fi
   finalfile=$DIR_ARCHIVE/$caso/atm/hist/$caso.cam.$ft.$yyyy-$st.zip.nc
   if [[ ! -f $finalfile ]]
   then
      input="$caso $ft $yyyy $st $member ${wkdir_cam} $finalfile" 
          # ADD the reservation for serial !!!
      ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -S qos_resv -t "24" -M 55000 -j create_cam_files_${ft}_${caso} -l $DIR_LOG/$caso/logs/ -d ${DIR_POST}/cam -s create_cam_files.sh -i "$input"
      input="$finalfile $caso $outdirC3S ${wkdir_cam} $ft ${checkfile_regridC3S_type}_${ft}"
          # ADD the reservation for serial !!!
      ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -S qos_resv -t "24" -M 55000 -p create_cam_files_${ft}_${caso} -j regrid_cam_${ft}_${caso} -l $DIR_CASES/$caso/logs/ -d ${DIR_POST}/cam -s regridFV_C3S.sh -i "$input"
   else
# meaning that preproc files have been done by create_cam_files.sh
# so submit without dependency
      input="$finalfile $caso $outdirC3S ${wkdir_cam} $ft ${checkfile_regridC3S_type}_${ft}"
          # ADD the reservation for serial !!!
      ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -S qos_resv -t "24" -M 55000 -j regrid_cam_${ft}_${caso} -l $DIR_CASES/$caso/logs/ -d ${DIR_POST}/cam -s regridFV_C3S.sh -i "$input"
   fi
         
done

# now wait that all of the ft files have been regridded
while `true`
do
   if [[ `ls ${checkfile_regridC3S_type}_h?_DONE|wc -l` -eq 3 ]]
   then
      break
   fi
   sleep 60
done
input="$ft $caso $outdirC3S $checkfile_all_camC3S_done $checkfile_qa"
          # ADD the reservation for serial !!!
${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -S qos_resv -t "24" -M 55000 -j check_C3S_atm_vars_${caso} -l $DIR_CASES/$caso/logs/ -d ${DIR_POST}/cam -s check_C3S_atm_vars.sh -i "$input"

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
#TEMPORARY COMMENTED
#if [ -d $WORK_SPS3/$caso ]
#then
#  cd $WORK_SPS3/$caso
#  rm -rf run
#  rm -rf bld
#  cd $WORK_SPS3
#  rmdir $caso
#fi
# now rm file not necessary for archiving
# NOT SURE WE NEED
#rm $DIR_ARCHIVE/$caso/rof/hist/$caso.rtm.h0.????-??.nc
#rm $DIR_ARCHIVE/$caso/lnd/hist/$caso.clm2.h0.????-??.nc
#rm $DIR_ARCHIVE/$caso/atm/hist/$caso.cam.h0.????-??.nc

#***********************************************************************
# Exit
#***********************************************************************
touch $checkfile_postproc_final
echo "Done."


exit 0

