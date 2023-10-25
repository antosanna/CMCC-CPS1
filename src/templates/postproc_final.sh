#!/bin/sh -l 

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. $DIR_UTIL/load_nco
. $DIR_UTIL/load_cdo

set -evxu


checkfile=$1
caso=EXPNAME
ic="DUMMYIC"
# NEW 202103: aggiunto argomento di debug in regridSEne60_C3S.sh e in postpc_clm.sh e if operational_user per checkrunlist

st=`./xmlquery RUN_STARTDATE|cut -d ':' -f2|sed 's/ //'|cut -d '-' -f2`
yyyy=`./xmlquery RUN_STARTDATE|cut -d ':' -f2|sed 's/ //'|cut -d '-' -f1`
set +euvx
   . ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -euvx
#
ens=`echo $caso|cut -d '_' -f 3|cut -c 2-3`
startdate=$yyyy$st

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

# directory creation
outdirC3S=${WORK_C3S}/$yyyy$st/
mkdir -p $outdirC3S
#***********************************************************************
# Cam files archiving
#***********************************************************************
# Standardization for CAM 
#***********************************************************************
cd $DIR_ARCHIVE/$caso/atm/hist/
if [ ! -f $WORK_C3S/$yyyy$st/${caso}_cam_C3SDONE ]
then
   filetyp="h1 h2 h3"
   for ft in $filetyp
   do
   #--------------------------------------------
   # cam define mulptiplier for timestep (daily,6h,12h)
   #--------------------------------------------
      case $ft in
        h1 ) mult=4 ;; # 6h
        h2 ) mult=2 ;; # 12h
        h3 ) mult=1 ;; # daily
      esac
      #--------------------------------------------
      #$caso.cam.$ft.nc is a temp file, input for $DIR_POST/regridSEne60_C3S.sh
      #--------------------------------------------
      if [ ! -f $caso.cam.$ft.$yyyy-$st.zip.nc ] 
      then
         echo "starting compression for file $ft "`date`
         $compress $caso.cam.$ft.$yyyy-$st-01-00000.nc pre.$caso.cam.$ft.$yyyy-$st.zip.nc
         ncatted -O -a ic,global,a,c,"$ic" pre.$caso.cam.$ft.$yyyy-$st.zip.nc
      fi
    
      nt=`cdo -ntime $DIR_ARCHIVE/$caso/atm/hist/pre.$caso.cam.$ft.$yyyy-$st.zip.nc`
    
      expected_ts=$(( $fixsimdays * $mult + 1 ))
      if [ $nt -lt $expected_ts  ]
      then
         body="ERROR Total number of timesteps for files pre.$caso.cam.$ft.$yyyy-$st.nc , ne to $expected_ts but is $nt. Exit "
         title="${CPSSYS} forecast ERROR "
         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
         exit 1
      elif [ $nt -gt $expected_ts  ]
      then
         ncks -O -F -d time,1,$expected_ts pre.$caso.cam.$ft.$yyyy-$st.zip.nc tmp.$caso.cam.$ft.$yyyy-$st.zip.nc  
         mv tmp.$caso.cam.$ft.$yyyy-$st.zip.nc pre.$caso.cam.$ft.$yyyy-$st.zip.nc   
      fi
   
         # remove nr.1 timestep according to filetyp $ft
      if [ $ft == "h3" ]
      then
         # take from 2nd timestep
         echo "start ncks for $ft "`date`
         ncks -O -F -d time,2, pre.$caso.cam.$ft.$yyyy-$st.zip.nc tmp.$caso.cam.$ft.$yyyy-$st.zip.nc  
         mv tmp.$caso.cam.$ft.$yyyy-$st.zip.nc $caso.cam.$ft.$yyyy-$st.zip.nc		      
         echo "end of ncks for $ft "`date`
      else
         # take all but last timestep
         echo "start ncks for $ft "`date`
         nstep=`cdo -ntime pre.$caso.cam.$ft.$yyyy-$st.zip.nc` 		
         nstepm1=$(($nstep - 1))
         ncks -O -F -d time,1,$nstepm1 pre.$caso.cam.$ft.$yyyy-$st.zip.nc tmp.$caso.cam.$ft.$yyyy-$st.zip.nc  
         mv tmp.$caso.cam.$ft.$yyyy-$st.zip.nc $caso.cam.$ft.$yyyy-$st.zip.nc			 	
         echo "end of ncks for $ft "`date`
      fi
   done  
   #--------------------------------------------
   # CAM C3S standardization
   #-------------------------------------------- 
   filetyp="h1 h2 h3"
   echo "start regrid CAM "`date`
   input="$caso $ic $outdirC3S $DIR_ARCHIVE/$caso/atm/hist/ $DIR_ARCHIVE/$caso/ice/hist 0"    # 0 meaning that postprocessing is done runtime
# modified 20201021  from parallelq to serialq_l
          # use the reservation
    ${DIR_UTIL}/submitcommand.sh -m $machine -q $parallelq_l -E yes -r $sla_serialID -S qos_resv -t "24" -M 55000 -j regrid_cam_${caso} -l $DIR_CASES/$caso/logs/ -d ${DIR_POST}/cam -s regridFV_C3S.sh -i "$input"


fi   # if della flag C3S_DONE

#***********************************************************************
# Standardization for CLM 
#***********************************************************************
if [ ! -f $WORK_C3S/$yyyy$st/${caso}_clm_C3SDONE ]
then
   cd $DIR_ARCHIVE/$caso/lnd/hist/
   ft="h1"
   case $ft in
     h1 ) mult=1 ;; # for land h1 is daily, multiplier=1
   esac
   ppp=`echo $caso|cut -d '_' -f 3 `
   if [ ! -f $caso.clm2.$ft.$yyyy-$st.zip.nc ]
   then
      $compress $caso.clm2.$ft.$yyyy-$st-01-00000.nc pre.$caso.clm2.$ft.$yyyy-$st.zip.nc
      ncatted -O -a ic,global,a,c,"$ic" pre.$caso.clm2.$ft.$yyyy-$st.zip.nc
 
     #--------------------------------------------
     # clm (II) check that number of timesteps is the expected one and remove extra timestep
     #--------------------------------------------
 
      expected_ts=$(( $fixsimdays * $mult + 1 ))
      nt=`cdo -ntime $DIR_ARCHIVE/$caso/lnd/hist/pre.$caso.clm2.$ft.$yyyy-$st.zip.nc`
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
      mv tmp.$caso.clm2.$ft.$yyyy-$st.zip.nc $caso.clm2.$ft.$yyyy-$st.zip.nc
   fi
   #--------------------------------------------
   # C3S standardization for CLM 
   # $caso.clm2.$ft.nc is a temp file, input for ${DIR_POST}/clm/postpc_clm.sh 
   #--------------------------------------------
   echo "start of postpc_clm "`date`
   input="$ppp $startdate $outdirC3S $ic $DIR_ARCHIVE/$caso/lnd/hist $caso 0"  #0 means done while running (1 if from archive)
   ${DIR_UTIL}/submitcommand.sh -m $machine -q $parallelq_l -E yes -M 6500 -r $sla_serialID -S qos_resv -t "24" -j postpc_clm_${caso} -l $DIR_CASES/$caso/logs/ -d ${DIR_POST}/clm -s postpc_clm.sh -i "$input"

fi

#***********************************************************************
# checkout the list
#***********************************************************************
cd $DIR_CASES/$caso/Tools/
if [ `whoami` == ${operational_user} ]
then
   ./checklist_run.sh $jobIDdummy True
fi

#***********************************************************************
# Remove $WORK_SPS3/$caso
#***********************************************************************
if [ -d $WORK_SPS3/$caso ]
then
  cd $WORK_SPS3/$caso
  rm -rf run
  rm -rf bld
  cd $WORK_SPS3
  rmdir $caso
fi
# now rm file not necessary for archiving
# NOT SURE WE NEED
#rm $DIR_ARCHIVE/$caso/rof/hist/$caso.rtm.h0.????-??.nc
#rm $DIR_ARCHIVE/$caso/lnd/hist/$caso.clm2.h0.????-??.nc
#rm $DIR_ARCHIVE/$caso/atm/hist/$caso.cam.h0.????-??.nc

#***********************************************************************
# Exit
#***********************************************************************
echo "Done."

exit 0

