#!/bin/sh -l 
#BSUB -J test_postproc_final_cam
#BSUB -e /work/csp/cp1/CPS/CMCC-CPS1/logs/tests/test_postproc_final_cam_%J.err
#BSUB -o /work/csp/cp1/CPS/CMCC-CPS1/logs/tests/test_postproc_final_cam_%J.out
#BSUB -P 0490
#BSUB -M 100
#BSUB -q s_medium

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. $DIR_UTIL/load_nco
. $DIR_UTIL/load_cdo

set -evxu

caso=cpl_XX_hyb_sps_t8
yyyy=2000
st=01
#
ens=01


. ${DIR_UTIL}/descr_ensemble.sh $yyyy
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
      checkfile=$wkdir/${caso}_cam_${ft}_done
      if [[ -f $checkfile ]]
      then
         continue
      fi
      finalfile=/work/csp/cp1/scratch/regrid_tests/CAM/$caso.cam.$ft.$yyyy-$st.zip.nc
      input="$caso $ft $yyyy $st $ens $checkfile $wkdir $finalfile" 
#      ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -E yes -r $sla_serialID -S qos_resv -t "24" -M 55000 -j create_cam_files_${ft}_${caso} -l $DIR_CASES/$caso/logs/ -d ${DIR_POST}/cam -s create_cam_files.sh -i "$input"
      ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -S qos_resv -t "24" -M 55000 -j create_cam_files_${ft}_${caso} -l $DIR_LOG/tests/ -d ${DIR_POST}/cam -s create_cam_files.sh -i "$input"
   done
   #--------------------------------------------
   # CAM C3S standardization
   #-------------------------------------------- 
   for ft in $filetyp
   do
      echo "start regrid CAM "`date`
      input="$ft $caso $ic $outdirC3S $DIR_ARCHIVE/$caso/atm/hist/ $DIR_ARCHIVE/$caso/ice/hist 0"    # 0 meaning that postprocessing is done runtime
# modified 20201021  from parallelq to serialq_l
          # use the reservation
# WILL BE    ${DIR_UTIL}/submitcommand.sh -m $machine -q $serailq_m -r $sla_serialID -S qos_resv -t "24" -p create_cam_files_h1_${caso} -w create_cam_files_h2_${caso} -W create_cam_files_h3_${caso} -M 55000 -j regrid_cam_${caso} -l $DIR_CASES/$caso/logs/ -d ${DIR_POST}/cam -s regridFV_C3S.sh -i "$input"
       ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -r $sla_serialID -S qos_resv -t "24" -M 55000 -j regrid_cam_${caso} -l $DIR_CASES/$caso/logs/ -d ${DIR_POST}/cam -s regridFV_C3S.sh -i "$input"

   done

fi   # if della flag C3S_DONE

#***********************************************************************
# Exit
#***********************************************************************
echo "Done."

exit 0

