#!/bin/sh -l 
#BSUB -J test_postproc_final_cam
#BSUB -e /work/csp/cp1/CPS/CMCC-CPS1/logs/tests/test_postproc_final_cam_%J.err
#BSUB -o /work/csp/cp1/CPS/CMCC-CPS1/logs/tests/test_postproc_final_cam_%J.out
#BSUB -P 0490
#BSUB -M 10000
#BSUB -q s_medium

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. $DIR_UTIL/load_nco
. $DIR_UTIL/load_cdo

set -evxu


caso=cpl_XX_hyb_sps_t8
ic="DUMMYIC"
# NEW 202103: aggiunto argomento di debug in regridSEne60_C3S.sh e in postpc_clm.sh e if operational_user per checkrunlist

yyyy=2000
st=01
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
#
ens=01


# directory creation
outdirC3S=${SCRATCHDIR}/C3S/$yyyy$st/
mkdir -p $outdirC3S
#***********************************************************************
# Cam files archiving
#***********************************************************************
# Standardization for CAM 
#***********************************************************************
wkdir=$SCRATCHDIR/work/$caso
mkdir -p $wkdir
cd $wkdir
if [ ! -f $outdirC3S/${caso}_cam_C3SDONE ]
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
      finalfile=/work/csp/cp1/scratch/regrid_tests/CAM/$caso.cam.$ft.$yyyy-$st.zip.nc  
      if [ ! -f $finalfile ]
      then
         echo "starting compression for file $ft "`date`
         if [[ ! -f $wkdir/pre.$caso.cam.$ft.$yyyy-$st.zip.nc ]]
         then
            $compress /work/csp/cp1/scratch/regrid_tests/CAM/$caso.cam.$ft.$yyyy-$st-01-00000.nc $wkdir/pre.$caso.cam.$ft.$yyyy-$st.zip.nc
         fi
         ncatted -O -a ic,global,a,c,"$ic" pre.$caso.cam.$ft.$yyyy-$st.zip.nc
      fi
    
      nt=`cdo -ntime $wkdir/pre.$caso.cam.$ft.$yyyy-$st.zip.nc`
    
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
         rsync -auv tmp.$caso.cam.$ft.$yyyy-$st.zip.nc pre.$caso.cam.$ft.$yyyy-$st.zip.nc   
      fi
   
         # remove nr.1 timestep according to filetyp $ft
      if [ $ft == "h3" ]
      then
         # take from 2nd timestep
         echo "start ncks for $ft "`date`
         ncks -O -F -d time,2, pre.$caso.cam.$ft.$yyyy-$st.zip.nc tmp.$caso.cam.$ft.$yyyy-$st.zip.nc  
         rsync -auv tmp.$caso.cam.$ft.$yyyy-$st.zip.nc $caso.cam.$ft.$yyyy-$st.zip.nc		      
         echo "end of ncks for $ft "`date`
      else
         # take all but last timestep
         echo "start ncks for $ft "`date`
         nstep=`cdo -ntime pre.$caso.cam.$ft.$yyyy-$st.zip.nc` 		
         nstepm1=$(($nstep - 1))
         ncks -O -F -d time,1,$nstepm1 pre.$caso.cam.$ft.$yyyy-$st.zip.nc tmp.$caso.cam.$ft.$yyyy-$st.zip.nc  
         rsync -auv tmp.$caso.cam.$ft.$yyyy-$st.zip.nc $finalfile
         echo "end of ncks for $ft "`date`
      fi
   done  
exit
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
# Exit
#***********************************************************************
echo "Done."

exit 0

