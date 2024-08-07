#!/bin/sh -l

# load variables from descriptor
set +euvx
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
#. $DIR_UTIL/condaactivation.sh
#condafunction activate $envcondacm3
set -euvx
echo "your conda environment is $CONDA_DEFAULT_ENV "

#----------------------------------------------------------
# get from the parent script start-date and perturbations
#----------------------------------------------------------
caso=$1
yyyy=`echo $1|cut -d '_' -f2|cut -c 1-4`
st=`echo $1|cut -d '_' -f2|cut -c 5-6`

set +euvx
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -euvx

ic=`cat $DIR_CASES/$caso/logs/ic_${caso}.txt`

cd $DIR_CASES/$caso
#----------------------------------------------------------
# Copy log_cheker from DIR_TEMPL in $caso
#----------------------------------------------------------

rsync -av $DIR_TEMPL/env_workflow_sps4.xml_${env_workflow_tag} $DIR_CASES/$caso/env_workflow.xml
if [[ `ls env_mach_specific.xml |wc -l` -ne 0 ]]
then
   echo "env_mach_specific is here "`ls env_mach_specific.xml`
else
   cp $DIR_TEMPL/env_mach_specific.xml $DIR_CASES/$caso
fi
if [[ $machine == "juno" ]]
then
   ./xmlchange MAX_TASKS_PER_NODE=72
   ./xmlchange MAX_MPITASKS_PER_NODE=72
  ./xmlchange PIO_NUMTASKS=-99
  ./xmlchange PIO_STRIDE=18
elif [[ $machine == "zeus" ]]
then
   ./xmlchange MAX_TASKS_PER_NODE=36
   ./xmlchange MAX_MPITASKS_PER_NODE=30
elif [[ $machine == "leonardo" ]] ; then
   module use -p $modpath
   ./xmlchange MAX_TASKS_PER_NODE=112
   ./xmlchange MAX_MPITASKS_PER_NODE=96
  ./xmlchange PIO_NUMTASKS=-99
fi
./case.setup --reset
./case.setup
./xmlchange BUILD_COMPLETE=TRUE
if [[ $typeofrun == "hindcast" ]]
then
   ./xmlchange --subgroup case.checklist prereq=0
else
   ./xmlchange --subgroup case.checklist prereq=1
fi

# cp and change script for nemo standardization
# THIS GOES IN env_workflow
sed -e "s/CASO/$caso/g;s/YYYY/$yyyy/g;s/mese/$st/g" $DIR_TEMPL/check_6months_output_in_archive.sh > $DIR_CASES/$caso/check_6months_output_in_archive_${caso}.sh
chmod u+x $DIR_CASES/$caso/check_6months_output_in_archive_${caso}.sh
outdirC3S=$DIR_ARCHIVE/C3S/$yyyy$st/
sed -e "s:CASO:$caso:g;s:IC:$ic:g;s:OUTDIRC3S:$outdirC3S:g" $DIR_POST/nemo/interp_ORCA2_1X1_gridT2C3S_template.sh > $DIR_CASES/$caso/interp_ORCA2_1X1_gridT2C3S_${caso}.sh
chmod u+x $DIR_CASES/$caso/interp_ORCA2_1X1_gridT2C3S_${caso}.sh
sed -e "s:CASO:$caso:g;s:IC:$ic:g;s:OUTDIRC3S:$outdirC3S:g" $DIR_POST/cice/interp_cice2C3S_template.sh > $DIR_CASES/$caso/interp_cice2C3S_${caso}.sh
chmod u+x $DIR_CASES/$caso/interp_cice2C3S_${caso}.sh
sed -e "s:EXPNAME:$caso:g;s:DUMMYIC:$ic:g;" $DIR_TEMPL/postproc_monthly.sh > $DIR_CASES/$caso/postproc_monthly_${caso}.sh
chmod u+x $DIR_CASES/$caso/postproc_monthly_${caso}.sh
sed -e "s:EXPNAME:$caso:g;s:DUMMYIC:$ic:g;" $DIR_TEMPL/postproc_C3S.sh > $DIR_CASES/$caso/postproc_C3S_${caso}.sh
chmod u+x $DIR_CASES/$caso/postproc_C3S_${caso}.sh

checktime=`date`
echo 'all scripts refreshed ' $checktime
