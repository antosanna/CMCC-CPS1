#!/bin/sh -l

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx
#----------------------------------------------------------
# get from the parent script start-date and perturbations
#----------------------------------------------------------
yyyy=$1
st=$2
pp=`printf '%.2d' $3`            # CAM perturbation 2 digits
ppland=`printf '%.2d' $4`
poce=`printf '%.2d' $5`
nrun=`printf '%.3d' $6`
flag_test=${7:-0}  # if set this flag disables the "true" run and activates 
                   # the test suites (just work for the specific test case 
                   # ${CPSSystem}_202110_054)
                   # 1=tests from lt_archive_C3S.sh

. ${DIR_UTIL}/descr_ensemble.sh $yyyy
caso=${CPSSystem}_${yyyy}${st}_${nrun}
if [[ `whoami` == "$operational_user" ]]
then
   flag_test=0
fi

###refcaseSPS,execesmSPS,exeocnSPS and refcaseSCEN,execesmSCEN,exeocnSCEN defined in $DIR_SPS35/descr_SPS3.5.sh
if [ $yyyy -ge 2015 ]; then
   refcase=$refcaseSCEN
else  #for hindcast period
   refcase=$refcaseHIST
fi
cesmexe=$DIR_EXE/cesm.exe.CPS1

ic='atm='$pp',lnd='$ppland',ocn='$poce''
#----------------------------------------------------------
#${yyyy}${st}_${nrun} define case name and reference 
#----------------------------------------------------------
ncdatanow=$IC_CAM_CPS_DIR1/$st/${CPSSYS}.cam.i.$yyyy-$st-01-00000.$pp.nc
#----------------------------------------------------------
# clean everything
#----------------------------------------------------------
$DIR_UTIL/clean_caso.sh $caso
#----------------------------------------------------------
# create the case as a clone from the reference
#----------------------------------------------------------
# NEW TO RESPECT ORIGINAL STRUCTURE -
# we prefer clone to newcase with usermods_dir because in the first case the case tree is built also without case.build and we do not wnat to build the case because we are going to use always the same executable
# refcase changes with scenario but the executable must not
$DIR_CESM/cime/scripts/create_clone -case $DIR_CASES/$caso -clone $DIR_CASES1/$refcase --cime-output-root $WORK_CPS

#----------------------------------------------------------
mkdir -p $DIR_CASES/$caso/logs

cd $DIR_CASES/$caso
#----------------------------------------------------------
# Copy log_cheker from DIR_TEMPL in $caso
#----------------------------------------------------------
# TO DO
# set-up the case
#----------------------------------------------------------
./case.setup
#----------------------------------------------------------
# this modify the env_build.xml to tell the model that it has already been compiled an to skip the building-up (taking more than 30')
#----------------------------------------------------------
./xmlchange BUILD_COMPLETE=TRUE
./xmlchange BUILD_STATUS=0

# TEMPORARY COMMENT!!!
#rsync -av $DIR_TEMPL/env_workflow_6months.xml $DIR_CASES/$caso/env_workflow.xml
#-----------
sed -i "s:cesm.std:$DIR_CASES/$caso/logs/$caso.std:g" $DIR_CASES/$caso/.case.run
sed -i "s:cesm.std:$DIR_CASES/$caso/logs/st_archive_${caso}.std:g" $DIR_CASES/$caso/case.st_archive
sed -i "s:cesm.std:$DIR_CASES/$caso/logs/nemo_rebuild_${caso}.std:g" $DIR_CASES/$caso/.case.nemo_rebuild
ncpl=48
echo "timestep = $((86400 / $ncpl))"
echo "vertical levels 46"
#----------------------------------------------------------
# define the first month run as hybrid
#----------------------------------------------------------
# CESM2.1 can use a refdir where to find all the needed restarts
# IC_NEMO_CPS_DIR and IC_CICE_CPS_DIR will contain physical fields
refdirIC=$SCRATCHDIR/IC_${yyyy}${st}/$nrun
mkdir -p $refdirIC
refcaseIC=ic_for_$caso
ln -sf $IC_NEMO_CPS_DIR/$st/${CPSSYS}.nemo.$yyyy-${st}-01-00000.$poce.nc $refdirIC/restart.nc
ln -sf $IC_CICE_CPS_DIR/$st/${CPSSYS}.cice.r.$yyyy-${st}-01-00000.$poce.nc $refdirIC/${refcaseIC}.cice.r.$yyyy-${st}-01-00000.nc
echo "$refcaseIC.cice.r.$yyyy-${st}-01-00000.nc" > $refdirIC/rpointer.ice
ln -sf $IC_CLM_CPS_DIR1/$st/${CPSSYS}.clm2.r.$yyyy-$st-01-00000.$ppland.nc $refdirIC/${refcaseIC}.clm2.r.$yyyy-${st}-01-00000.nc
echo "${refcaseIC}.clm2.r.$yyyy-${st}-01-00000.nc" > $refdirIC/rpointer.lnd
ln -sf $IC_CLM_CPS_DIR1/$st/${CPSSYS}.hydros.r.$yyyy-$st-01-00000.$ppland.nc $refdirIC/${refcaseIC}.hydros.r.$yyyy-${st}-01-00000.nc
echo "${refcaseIC}.hydros.r.$yyyy-${st}-01-00000.nc" > $refdirIC/rpointer.rof

stop_op=nmonths
stop_n=1
./xmlchange RUN_TYPE=hybrid
# here we can test if branch....
./xmlchange RUN_STARTDATE=$yyyy-$st-01
./xmlchange RUN_REFDATE=$yyyy-$st-01
./xmlchange RUN_REFCASE=${refcaseIC}
./xmlchange RUN_REFDIR=${refdirIC}
./xmlchange GET_REFCASE=TRUE
./xmlchange STOP_OPTION=$stop_op
./xmlchange STOP_N=$stop_n
./xmlchange REST_OPTION=$stop_op
./xmlchange REST_N=$stop_n
./xmlchange CONTINUE_RUN=FALSE
./xmlchange RESUBMIT=$(($nmonfore - 1))
./xmlchange ATM_NCPL=$ncpl
./xmlchange OCN_NCPL=24
./xmlchange ROF_NCPL=8
./xmlchange INFO_DBUG=0
./xmlchange NEMO_REBUILD=TRUE

# cp and change script for nemo standardization
# THIS GOES IN env_workflow
#cp $DIR_UTIL/interp_ORCA2_1X1_gridT2C3S.sh $DIR_CASES/$caso/
#chmod u+x $DIR_CASES/$caso/interp_ORCA2_1X1_gridT2C3S.sh

# cp and change lt_archive
#sed 's/ic="dummy"/ic="'$ic'"/g;s/EXPNAME/'$caso'/g' $DIR_TEMPL/lt_archive_C3S.sh > $DIR_CASES/$caso/lt_archive_C3S.sh
#chmod u+x $DIR_CASES/$caso/lt_archive_C3S.sh

#DIR_TEMPL/template.hindcast_checklist submitted by env_workflow.xml
# TO DO chmod u+x $DIR_CASES/$caso/Tools/checklist_run.sh

#----------------------------------------------------------
# $caso.l_archive
#----------------------------------------------------------
#env_workflow.xml
#----------------------------------------------------------
# modify the default Nemo postprocessing
#----------------------------------------------------------
#$DIR_TEMPL/template.nemo_rebuild4cmcc-cm in env_workflow.xml
#----------------------------------------------------------

#----------------------------------------------------------
# CAM  TEMPLATE
#----------------------------------------------------------
echo "IC CAM $ncdatanow"
sed -i '/ncdata/d' $DIR_CASES/$caso/user_nl_cam
echo "ncdata='$ncdatanow'">>$DIR_CASES/$caso/user_nl_cam

#----------------------------------------------------------

# QUESTO DIVENTERA UN MODULO
cp $cesmexe $WORK_CPS/$caso/bld/cesm.exe

cd $DIR_CASES/$caso
#----------------------------------------------------------
# add the notification on error to the job script
#----------------------------------------------------------
#----------------------------------------------------------
# submit first month
#----------------------------------------------------------

exit
if [[ $flag_test -ne 0 ]]
then
#   if [[ $flag_test -eq 1 ]]
#   then
# modify environment files to set a continue run
#      ./xmlchange CONTINUE_RUN=TRUE
#      sed -e "s:NRUN:$nrun:g" $DIR_TEST_SUITE/test_from_lt_archive_C3S.run > $DIR_CASES/$caso/test_from_lt_archive_C3S_${nrun}.run
#      ${DIR_UTIL}/submitcommand.sh -m $machine -Z basic -d $DIR_CASES/$caso -s test_from_lt_archive_C3S_${nrun}.run
#   fi
   echo "not implemented yet"
else
    $DIR_CASES/$caso/case.submit
fi
checktime=`date`
echo 'run submitted ' $checktime
