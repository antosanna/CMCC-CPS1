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
                   # ${SPSSystem}_202110_054)
                   # 1=tests from lt_archive_C3S.sh

. ${DIR_UTIL}/descr_ensemble.sh $yyyy
caso=${SPSSystem}_${yyyy}${st}_${nrun}
if [[ `whoami` == "$operational_user" ]]
then
   flag_test=0
fi

if [ $yyyy -ge $yyyySCEN ]; then
   refcase=$refcaseSCEN
else  #for hindcast period
   refcase=$refcaseHIST
fi
# this should become a module on Juno
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

rsync -av $DIR_TEMPL/env_workflow_sps4.xml_${env_workflow_tag} $DIR_CASES/$caso/env_workflow.xml
#----------------------------------------------------------
# TO DO
# set-up the case after modfication env_workflow
#----------------------------------------------------------
./case.setup --reset
./case.setup
./xmlchange BUILD_COMPLETE=TRUE
#----------------------------------------------------------
# CESM2.1 can use a refdir where to find all the needed restarts
# IC_NEMO_CPS_DIR and IC_CICE_CPS_DIR will contain physical fields
refdirIC=$SCRATCHDIR/IC_${yyyy}${st}/$nrun
mkdir -p $refdirIC
refcaseIC=ic_for_$caso
ln -sf $IC_NEMO_CPS_DIR/$st/${CPSSYS}.nemo.r.$yyyy-${st}-01-00000.$poce.nc $refdirIC/${refcaseIC}_00000001_restart.nc
ln -sf $IC_CICE_CPS_DIR/$st/${CPSSYS}.cice.r.$yyyy-${st}-01-00000.$poce.nc $refdirIC/${refcaseIC}.cice.r.$yyyy-${st}-01-00000.nc
echo "$refcaseIC.cice.r.$yyyy-${st}-01-00000.nc" > $refdirIC/rpointer.ice
ln -sf $IC_CLM_CPS_DIR/$st/${CPSSYS}.clm2.r.$yyyy-$st-01-00000.$ppland.nc $refdirIC/${refcaseIC}.clm2.r.$yyyy-${st}-01-00000.nc
echo "${refcaseIC}.clm2.r.$yyyy-${st}-01-00000.nc" > $refdirIC/rpointer.lnd
ln -sf $IC_CLM_CPS_DIR/$st/${CPSSYS}.hydros.r.$yyyy-$st-01-00000.$ppland.nc $refdirIC/${refcaseIC}.hydros.r.$yyyy-${st}-01-00000.nc
echo "${refcaseIC}.hydros.r.$yyyy-${st}-01-00000.nc" > $refdirIC/rpointer.rof

#-----------
ncpl=48
echo "timestep = $((86400 / $ncpl))"
echo "vertical levels 46"
stop_op=nmonths
# here we can test if branch....
./xmlchange RUN_STARTDATE=$yyyy-$st-01
./xmlchange RUN_REFDATE=$yyyy-$st-01
./xmlchange RUN_REFCASE=${refcaseIC}
./xmlchange RUN_REFDIR=${refdirIC}
./xmlchange STOP_OPTION=$stop_op
./xmlchange REST_OPTION=$stop_op
./xmlchange RESUBMIT=$(($nmonfore - 1))
./xmlchange ATM_NCPL=$ncpl
./xmlchange INFO_DBUG=0
./xmlchange NEMO_REBUILD=TRUE  

# cp and change script for nemo standardization
# THIS GOES IN env_workflow
sed -e "s/CASO/$caso/g;s/YYYY/$yyyy/g;s/ST/$st/g" $DIR_TEMPL/check_6months_output_in_archive.sh > $DIR_CASES/$caso/check_6months_output_in_archive_${caso}.sh
chmod u+x $DIR_CASES/$caso/check_6months_output_in_archive_${caso}.sh
outdirC3S=$DIR_ARCHIVE/C3S/$yyyy$st/
sed -e "s:CASO:$caso:g;s:IC:$ic:g;s:OUTDIRC3S:$outdirC3S:g" $DIR_POST/nemo/interp_ORCA2_1X1_gridT2C3S_template.sh > $DIR_CASES/$caso/interp_ORCA2_1X1_gridT2C3S_${caso}.sh
chmod u+x $DIR_CASES/$caso/interp_ORCA2_1X1_gridT2C3S_${caso}.sh
sed -e "s:CASO:$caso:g;s:IC:$ic:g;s:OUTDIRC3S:$outdirC3S:g" $DIR_POST/cice/interp_cice2C3S_template.sh > $DIR_CASES/$caso/interp_cice2C3S_${caso}.sh
chmod u+x $DIR_CASES/$caso/interp_cice2C3S_${caso}.sh
sed -e "s:EXPNAME:$caso:g;s:DUMMYIC:$ic:g;" $DIR_TEMPL/postproc_monthly.sh > $DIR_CASES/$caso/postproc_monthly_${caso}.sh
chmod u+x $DIR_CASES/$caso/postproc_monthly_${caso}.sh
sed -e "s:EXPNAME:$caso:g;s:DUMMYIC:$ic:g;" $DIR_TEMPL/postproc_final.sh > $DIR_CASES/$caso/postproc_final_${caso}.sh
chmod u+x $DIR_CASES/$caso/postproc_monthly_${caso}.sh

mkdir -p $DIR_CASES/$caso/logs


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

#exit
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
    conda activate $envcondacm3
    $DIR_CASES/$caso/case.submit
fi
checktime=`date`
echo 'run submitted ' $checktime
