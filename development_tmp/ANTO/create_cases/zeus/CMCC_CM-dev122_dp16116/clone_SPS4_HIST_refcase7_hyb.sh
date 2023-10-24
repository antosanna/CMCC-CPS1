#!/bin/sh -l
#BSUB -J refcase
#BSUB -e logs/refcase_%J.err
#BSUB -o logs/refcase_%J.out
#BSUB -o logs/refcase_%J.out
set -euvx

# Created 2023-03-27 10:07:47
#
#ANDRANNO AGGIUNTI QUESTI in env_workflow.xml
##     <entry id="BATCH_COMMAND_FLAGS" value="-q p_medium -P 0566 -W 04:00 -x -app cm3">
#    <entry id="BATCH_COMMAND_FLAGS" value="-q s_medium -P 0566 -W 02:00 -x  -app SERIAL_cm3">
#PER NEMO_REBUILD
#    <entry id="BATCH_COMMAND_FLAGS" value="-q s_medium -P 0566 -W 02:00 -x -app SERIAL_cm3">

here=$PWD
refcase=SPS4_HIST_hyb_refcase7
caso=SPS4_HIST_hyb_refcase8_hyb
DIR_CASES="/work/csp/as34319/CPS/CMCC-CPS1/cases/"
CASEDIR="/work/csp/as34319/CPS/CMCC-CPS1/cases/$caso"
if [[ -d $CASEDIR ]]
then
   rm -rf $CASEDIR
fi

/users_home/csp/sps-dev/CMCC_CM-dev122/cime/scripts/create_clone --case "${CASEDIR}" --clone $DIR_CASES/$refcase


cd $DIR_CASES/$caso
#./case.setup --reset
./case.setup

#cp /work/$DIVISION/$USER/scratch/$refcase/user_nl_* $CASEDIR

# THIS TAKES 10 MIN
./case.build
#SECTION FOR NEMO 
./xmlchange RUN_REFDIR=/work/csp/as34319/restart_cps_test
# here restart copied from Juno with
#       mv 19921001_001_restart.nc restart.nc
# and
#       mv 19920930_MB0.cice.r.1992-10-01-00000.nc cm3_cam122_cpl2000-bgc_t01.cice.r.0020-01-01-00000.nc
./xmlchange RUN_REFCASE=cm3_cam122_cpl2000-bgc_t01
./xmlchange RUN_REFDATE=0020-01-01
./xmlchange GET_REFCASE=TRUE
./xmlchange RUN_STARTDATE=2000-01-01
./xmlchange RUN_TYPE=hybrid
