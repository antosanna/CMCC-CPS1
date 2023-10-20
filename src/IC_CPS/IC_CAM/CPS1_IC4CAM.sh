#!/bin/sh -l
# AGGIUNGERE STRIDE!!!!
# THIS JOB RUNS WITH ITS OWN user_nl_cam AND ITS SPECIFIC NCPL=192

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_nco
. ${DIR_UTIL}/descr_ensemble.sh

set -euvx
#----------------------------------------------------------
# get from the parent script start-date and perturbations
#----------------------------------------------------------
yyin=$1
mmin=$2
ddin=$3
pp=$4
caso=$5
ncpl=$6
bk=$7
ncdata=$8
ICfile=${9}
refdir_refcase_rest=${10}
refcase_rest=${11}
yyyy=${12}
st=${13}

refdate_rest=$yyin-$mmin-01 
startdate=$yyyy${st}01
#if [ $bk -eq 1 ]
#then
#   bkoce=${11}
#   bkice=${12}
#   bkclm=${13}
#   bkrtm=${14}
#   repo_rest=/work/csp/as34319/restart_cps_test/0020-01-01-00000
#   refcase_rest=cm3_cam122_cpl2000-bgc_t01
#   refdate_rest=0020-01-01
#fi
#------------------------------------------------------------

diff=`${DIR_UTIL}/datediff.sh $startdate $yyin$mmin$ddin`
#

refcase=SPS4_HIST_hyb_refcase
# WILL BE A MODULE
cesmexe=$DIR_EXE/cesm.exe.CPS1
#
#----------------------------------------------------------
# clean everything
#----------------------------------------------------------
if [ -d $WORK_CPS/$caso ]
then
    cd $WORK_CPS/
    rm -rf $caso
fi
if [ -d $DIR_CASES/$caso ] 
then
   cd $DIR_CASES
   rm -rf $caso
fi
#----------------------------------------------------------
# create the case as a lone from the referenc
#----------------------------------------------------------
$DIR_CESM/cime/scripts/create_clone --case $DIR_CASES/$caso --clone $DIR_CASES/$refcase --cime-output-root $WORK_CPS
#----------------------------------------------------------
mkdir -p $DIR_CASES/$caso/logs
cd $DIR_CASES/$caso
#----------------------------------------------------------
# Copy log_cheker from DIR_TEMPL in $caso
#----------------------------------------------------------
#cp ${DIR_TEMPL}/log_checker_launcher.sh $DIR_CASES/$caso/log_checker_launcher.sh
#cp ${DIR_TEMPL}/log_checker.sh $DIR_CASES/$caso/log_checker.sh
#sed -i "s:ICTOBECHANGEDBYSED:$ncdata:g" $DIR_CASES/$caso/log_checker.sh
sed "s:CASO:$caso:g" $DIR_TEMPL/change_timestep.sh > $DIR_CASES/$caso/change_timestep.sh
chmod u+x $DIR_CASES/$caso/change_timestep.sh
#----------------------------------------------
# copy rhe env_workflow.xml for cam IC
#----------------------------------------------
# TEMPORARY COMMENT!!!
#----------------------------------------------------------
# set-up the case
#----------------------------------------------------------
./case.setup
#----------------------------------------------------------
# this modify the env_build.xml to tell the model that it has already been compiled an to skip the building-up (taking more than 30')
#----------------------------------------------------------
#./xmlchange BUILD_STATUS=0

cd $DIR_CASES/$caso

#----------------------------------------------------------
# CAM  IC $IC_CPS_guess/CAM
#----------------------------------------------------------
cp $DIR_TEMPL/user_nl_ICcam $DIR_CASES/$caso/user_nl_cam
sed -i '/ncdata/d' user_nl_cam
echo "ncdata='$ncdata'">>user_nl_cam
echo "inithist = 'ENDOFRUN'" >>user_nl_cam

#
echo "timestep = $((86400 / $ncpl))"
echo "vertical levels 86"
#----------------------------------------------------------
# define the first month run as hybrid
#----------------------------------------------------------
./xmlchange RUN_STARTDATE=$yyin-$mmin-$ddin
./xmlchange RUN_REFCASE=$refcase_rest
./xmlchange RUN_REFDIR=$refdir_refcase_rest
./xmlchange RUN_REFDATE=$yyin-$mmin-$ddin
./xmlchange GET_REFCASE=TRUE
./xmlchange STOP_OPTION=ndays
./xmlchange STOP_DATE=$startdate
./xmlchange STOP_N=$diff
./xmlchange ATM_NCPL=$ncpl
#./xmlchange PIO_NUMTASKS=4   NON VA
#./xmlchange PIO_STRIDE=18
#./xmlchange PIO_NUMTASKS=16   NON VA
#./xmlchange PIO_STRIDE=18

# AL MOMENTO NON CI SONO
cp $cesmexe $WORK_CPS/$caso/bld/cesm.exe
sed -i "s:cesm.std:$DIR_LOG/$typeofrun/$st/IC_CAM/$caso.std:g" $DIR_CASES/$caso/.case.run

cd $DIR_CASES/$caso
rsync -av $DIR_TEMPL/env_workflow_IC_cam.xml $DIR_CASES/$caso/env_workflow.xml
./case.setup --reset
./xmlchange BUILD_COMPLETE=TRUE
#----------------------------------------------------------
# submit first month
#----------------------------------------------------------
./case.submit
checktime=`date`
echo 'run submitted ' $checktime

