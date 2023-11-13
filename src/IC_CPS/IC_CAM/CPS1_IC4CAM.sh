#!/bin/sh -l
# AGGIUNGERE STRIDE!!!!
# THIS JOB RUNS WITH ITS OWN user_nl_cam AND ITS SPECIFIC NCPL=192

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. ${DIR_UTIL}/load_nco

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
ncdata=$7
ICfile=${8}
refdir_refcase_rest=${9}
refcase_rest=${10}
yyyy=${11}
st=${12}

. ${DIR_UTIL}/descr_ensemble.sh $yyyy
refdate_rest=$yyin-$mmin-01 
startdate=$yyyy${st}01
#------------------------------------------------------------

diff=`${DIR_UTIL}/datediff.sh $startdate $yyin$mmin$ddin`
#

if [[ $yyyy -ge $yyyySCEN ]]
then
   refcase=$refcaseSCEN
else
   refcase=$refcaseHIST
fi
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
# Copy env_workflow_IC_cam.xml_juno from DIR_TEMPL in $caso
# and set the proper SLA to the file.xml
#!!!!!! NON ANCORA IMPLEMENTATA
#----------------------------------------------------------
#----------------------------------------------------------
# DA FARE
# Copy log_cheker from DIR_TEMPL in $caso
#----------------------------------------------------------
#cp ${DIR_TEMPL}/log_checker_launcher.sh $DIR_CASES/$caso/log_checker_launcher.sh
#cp ${DIR_TEMPL}/log_checker.sh $DIR_CASES/$caso/log_checker.sh
#sed -i "s:ICTOBECHANGEDBYSED:$ncdata:g" $DIR_CASES/$caso/log_checker.sh
#sed "s:CASO:$caso:g" $DIR_TEMPL/change_timestep.sh > $DIR_CASES/$caso/change_timestep.sh
#chmod u+x $DIR_CASES/$caso/change_timestep.sh
#----------------------------------------------
# set-up the case
#----------------------------------------------------------
#----------------------------------------------------------
# this modify the env_build.xml to tell the model that it has already been compiled an to skip the building-up (taking more than 30')
#----------------------------------------------------------
rsync -av $DIR_TEMPL/env_workflow_IC_cam.xml_${env_workflow_tag} env_workflow.xml
./case.setup --reset
./case.setup
./xmlchange BUILD_COMPLETE=TRUE

#----------------------------------------------------------
# CAM  IC $IC_CPS_guess/CAM
#----------------------------------------------------------
sed -i '/ncdata/d' user_nl_cam
sed -i '/inithist/d' user_nl_cam
echo "ncdata='$ncdata'">>user_nl_cam
echo "inihist='ENDOFRUN'">>user_nl_cam

#
echo "timestep = $((86400 / $ncpl))"
echo "vertical levels 83"
#----------------------------------------------------------
# define the first month run as hybrid
#----------------------------------------------------------
./xmlchange RUN_STARTDATE=$yyin-$mmin-$ddin
./xmlchange RUN_REFCASE=$refcase_rest
./xmlchange RUN_REFDIR=$refdir_refcase_rest
./xmlchange RUN_REFDATE=$yyin-$mmin-$ddin
./xmlchange STOP_DATE=$startdate
./xmlchange STOP_N=$diff
./xmlchange ATM_NCPL=$ncpl

# AL MOMENTO NON CI SONO
cp $cesmexe $WORK_CPS/$caso/bld/cesm.exe
#QUESTO NON FUNZIONA: spostato in env_workflow
#sed -i "s:cesm.std:$DIR_LOG/$typeofrun/$st/IC_CAM/$caso.std:g" $DIR_CASES/$caso/.case.run
# al momento del submit lo riscrive

#----------------------------------------------------------
# submit first month
#----------------------------------------------------------
set +euvx
. $DIR_UTIL/condaactivation.sh
condafunction activate $envcondacm3
set -euvx
./case.submit
checktime=`date`
echo 'run submitted ' $checktime

