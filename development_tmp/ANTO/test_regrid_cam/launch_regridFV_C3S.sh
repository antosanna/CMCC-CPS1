   #--------------------------------------------
   # CAM C3S standardization
   #-------------------------------------------- 
set -euvx
   caso=cpl_XX_hyb_sps_t8
   echo "start regrid CAM "`date`
   yyyy=2000
   st=01
   ic="mama"
   outdirC3S=${SCRATCHDIR}/C3S/$yyyy$st/
#   input="$caso $ic $outdirC3S $DIR_ARCHIVE/$caso/atm/hist/ $DIR_ARCHIVE/$caso/ice/hist 0"    # 0 meaning that postprocessing is done runtime
   input="$caso $ic $outdirC3S  /work/csp/cp1/scratch/work/cpl_XX_hyb_sps_t8 0"    # 0 meaning that postprocessing is done runtime
# modified 20201021  from parallelq to serialq_l
          # use the reservation
#    ${DIR_UTIL}/submitcommand.sh -m $machine -q $parallelq_l -E yes -r $sla_serialID -S qos_resv -t "24" -p create_cam_files_h1_${caso} -w create_cam_files_h2_${caso} -W create_cam_files_h3_${caso} -M 55000 -j regrid_cam_${caso} -l $DIR_CASES/$caso/logs/ -d ${DIR_POST}/cam -s regridFV_C3S.sh -i "$input"
    ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -S qos_resv -t "24" -p create_cam_files_h1_${caso} -w create_cam_files_h2_${caso} -W create_cam_files_h3_${caso} -M 55000 -j regrid_cam_${caso} -l $DIR_CASES/$caso/logs/ -d ${DIR_POST}/cam -s regridFV_C3S.sh -i "$input"



#***********************************************************************
# Exit
#***********************************************************************
echo "Done."

exit 0

