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

checkfile_qa=$DIR_CASES/$caso/logs/qa_started_${startdate}_0${member}_ok
# directory creation
outdirC3S=${WORK_C3S}/$yyyy$st/
mkdir -p $outdirC3S
#***********************************************************************
# Cam files archiving
#***********************************************************************
# Standardization for CAM 
#***********************************************************************
wkdir=$SCRATCHDIR/regrid_C3S/CAM/$yyyy$st
mkdir -p $wkdir
checkfile_all_camC3S_done=$wkdir/${caso}_all_cam_C3SDONE
filetyp="h1 h2 h3"
for ft in $filetyp
do
   checkfile_regridC3S_ft=$wkdir/${caso}_cam_${ft}_regrid_C3Sdone
   if [[ -f $checkfile_regridC3S_ft ]]
   then
# meaning that preproc files have been done by create_cam_files.sh
# and regridded by regridFV_C3S.sh
      continue
   fi
   finalfile=$DIR_ARCHIVE/$caso/atm/hist/$caso.cam.$ft.$yyyy-$st.zip.nc
   if [[ ! -f $finalfile ]]
   then
      input="$caso $ft $yyyy $st $member $wkdir $finalfile" 
          # ADD the reservation for serial !!!
      ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -S qos_resv -t "24" -M 55000 -j create_cam_files_${ft}_${caso} -l $DIR_LOG/$caso/logs/ -d ${DIR_POST}/cam -s create_cam_files.sh -i "$input"
      input="$finalfile $caso $outdirC3S $wkdir $ft $checkfile_regridC3S_ft"
          # ADD the reservation for serial !!!
      ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -S qos_resv -t "24" -M 55000 -p create_cam_files_${ft}_${caso} -j regrid_cam_${ft}_${caso} -l $DIR_CASES/$caso/logs/ -d ${DIR_POST}/cam -s regridFV_C3S.sh -i "$input"
   else
# meaning that preproc files have been done by create_cam_files.sh
# so submit without dependency
      input="$finalfile $caso $outdirC3S $wkdir $ft $checkfile_regridC3S_ft"
          # ADD the reservation for serial !!!
      ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -S qos_resv -t "24" -M 55000 -j regrid_cam_${ft}_${caso} -l $DIR_CASES/$caso/logs/ -d ${DIR_POST}/cam -s regridFV_C3S.sh -i "$input"
   fi
         
done

# now wait that all of the ft files have been regridded
while `true`
do
   if [[ -f $wkdir/${caso}_cam_h1_regrid_C3Sdone ]] && [[ -f $wkdir/${caso}_cam_h2_regrid_C3Sdone ]] && [[ -f $wkdir/${caso}_cam_h3_regrid_C3Sdone ]] 
   then
      break
   fi
   sleep 60
done
input="$ft $caso $outdirC3S $checkfile_all_camC3S_done $checkfile_qa"
          # ADD the reservation for serial !!!
${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -S qos_resv -t "24" -M 55000 -j check_C3S_atm_vars_${caso} -l $DIR_CASES/$caso/logs/ -d ${DIR_POST}/cam -s check_C3S_atm_vars.sh -i "$input"

#***********************************************************************
# Standardization for CLM 
#***********************************************************************
wkdir=$SCRATCHDIR/regrid_C3S/CLM/$yyyy$st
mkdir -p $wkdir
checkfile_clm=$wkdir/${caso}_clm_C3SDONE
if [ ! -f $checkfile_clm ]
then
   cd $wkdir
   ft="h1"
   case $ft in
     h1 ) mult=1 ;; # for land h1 is daily, multiplier=1
   esac
   ppp=`echo $caso|cut -d '_' -f 3 `
   if [ ! -f $caso.clm2.$ft.$yyyy-$st.zip.nc ]
   then
      $compress $DIR_ARCHIVE/$caso/lnd/hist/$caso.clm2.$ft.$yyyy-$st-01-00000.nc pre.$caso.clm2.$ft.$yyyy-$st.zip.nc
      ncatted -O -a ic,global,a,c,"$ic" pre.$caso.clm2.$ft.$yyyy-$st.zip.nc

     #--------------------------------------------
     # clm (II) check that number of timesteps is the expected one and remove extra timestep
     #--------------------------------------------

      expected_ts=$(( $fixsimdays * $mult + 1 ))
      nt=`cdo -ntime pre.$caso.clm2.$ft.$yyyy-$st.zip.nc`
      if [ $nt -lt $expected_ts  ]
      then
          body="ERROR Total number of timesteps for file pre.$caso.clm2.$ft.$yyyy-$st.zip.nc , ne to $expected_ts but is $nt. Exit "
          title="${CPSSYS} forecast notification - ERROR "
          ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"  
          exit 1
      fi
     # remove nr.1 timestep according to filetyp $ft
     # take from 2nd timestep
      echo "start of ncks for clm one file "`date`
      ncks -O -F -d time,2, pre.$caso.clm2.$ft.$yyyy-$st.zip.nc tmp.$caso.clm2.$ft.$yyyy-$st.zip.nc
      echo "end of ncks for clm one file "`date`
      mv tmp.$caso.clm2.$ft.$yyyy-$st.zip.nc $DIR_ARCHIVE/$caso/lnd/hist/$caso.clm2.$ft.$yyyy-$st.zip.nc
   fi
   #--------------------------------------------
   # C3S standardization for CLM 
   # $caso.clm2.$ft.nc is a temp file, input for ${DIR_POST}/clm/postpc_clm.sh 
   #--------------------------------------------
   echo "start of postpc_clm "`date`
   input="$ppp $startdate $outdirC3S $DIR_ARCHIVE/$caso/lnd/hist $caso $checkfile_clm $checkfile_qa 0"  #0 means done while running (1 if from archive)
#TEMPORARY
#   ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -M 6500 -r $sla_serialID -S qos_resv -t "24" -j postpc_clm_${caso} -l $DIR_CASES/$caso/logs/ -d ${DIR_POST}/clm -s postpc_clm.sh -i "$input"
   ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -M 6500 -S qos_resv -t "24" -j postpc_clm_${caso} -l $DIR_CASES/$caso/logs/ -d ${DIR_POST}/clm -s postpc_clm.sh -i "$input"

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
touch checkfile_postproc_final
echo "Done."


exit 0

