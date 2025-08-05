#!/bin/sh -l

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx
#----------------------------------------------------------
# get from the parent script start-date and perturbations
#----------------------------------------------------------
module use -p $modpath
yyyy=YYYY
st=STDATE
pp=`printf '%.2d' PATM`            # CAM perturbation 2 digits
ppland=`printf '%.2d' PLAND`
poce=`printf '%.2d' POCE`
nrun=`printf '%.3d' NRUN`

. ${DIR_UTIL}/descr_ensemble.sh $yyyy
caso=${SPSSystem}_${yyyy}${st}_${nrun}
if [[ `whoami` == "$operational_user" ]]
then
   flag_test=0
fi

if [ $yyyy$st -ge ${yyyySCEN}07 ]; then
   refcase=$refcaseSCEN
else  #for hindcast period
   refcase=$refcaseHIST
fi
cesmexe=$DIR_EXE1/cesm.exe.CPS1_${machine}
mkdir -p $DIR_CASES

ic='atm='$pp',lnd='$ppland',ocn='$poce''
#----------------------------------------------------------
ncdatanow=$IC_CAM_CPS_DIR1/$st/${CPSSYS}.cam.i.$yyyy-$st-01-00000.$pp.nc
#----------------------------------------------------------
# clean everything
#----------------------------------------------------------
$DIR_UTIL/clean_caso.sh $caso
#----------------------------------------------------------
# create the case as a clone from the reference
#----------------------------------------------------------
# refcase changes with scenario but the executable must not
set +euvx
if [[ $machine == "leonardo" ]]
then
   $DIR_CESM/cime/scripts/create_clone --case $DIR_CASES/$caso --clone /leonardo_work/CMCC_Copernic_4/CPS/CMCC-CPS1/cases/$refcase --cime-output-root $WORK_CPS
else
   $DIR_CESM/cime/scripts/create_clone --case $DIR_CASES/$caso --clone $DIR_CASES1/$refcase --cime-output-root $WORK_CPS
fi

set -euvx
#----------------------------------------------------------
mkdir -p $DIR_CASES/$caso/logs
echo "$ic" > $DIR_CASES/$caso/logs/ic_${caso}.txt

cd $DIR_CASES/$caso
#----------------------------------------------------------
# Copy log_cheker from DIR_TEMPL in $caso  TO BE DONE
#----------------------------------------------------------

if [[ $USER == "$operational_user" ]]
then
   rsync -av $DIR_TEMPL/env_workflow_sps4.xml_${env_workflow_tag} $DIR_CASES/$caso/env_workflow.xml
   rsync -av $DIR_TEMPL/env_batch.xml_${env_workflow_tag} $DIR_CASES/$caso/env_batch.xml
   if [[ $machine == "leonardo" ]] ; then
       rsync -av $DIR_TEMPL/env_mach_specific.xml_${env_workflow_tag} $DIR_CASES/$caso/env_mach_specific.xml
   fi
else
   rsync -av $DIR_TEMPL/env_workflow_sps4.xml_${env_workflow_tag}_test $DIR_CASES/$caso/env_workflow.xml
fi
#----------------------------------------------------------
./case.setup --reset
if [[ $machine == "leonardo" ]] ; then
   rsync -av $DIR_TEMPL/env_mach_specific.xml_${env_workflow_tag} $DIR_CASES/$caso/env_mach_specific.xml
fi
./case.setup
./xmlchange BUILD_COMPLETE=TRUE
rsync -av $DIR_TEMPL/file_def_nemo-oce.xml $DIR_CASES/$caso/Buildconf/nemoconf/
#----------------------------------------------------------
# CESM2.1 can use a refdir where to find all the needed restarts
# IC_NEMO_CPS_DIR and IC_CICE_CPS_DIR will contain physical fields
refdirIC=$SCRATCHDIR/IC_${yyyy}${st}/$nrun
mkdir -p $refdirIC
refcaseIC=ic_for_$caso
ln -sf $IC_NEMO_CPS_DIR1/$st/${CPSSYS}.nemo.r.$yyyy-${st}-01-00000.$poce.nc $refdirIC/${refcaseIC}_00000001_restart.nc
ln -sf $IC_CICE_CPS_DIR1/$st/${CPSSYS}.cice.r.$yyyy-${st}-01-00000.$poce.nc $refdirIC/${refcaseIC}.cice.r.$yyyy-${st}-01-00000.nc
echo "$refcaseIC.cice.r.$yyyy-${st}-01-00000.nc" > $refdirIC/rpointer.ice
ln -sf $IC_CLM_CPS_DIR1/$st/${CPSSYS}.clm2.r.$yyyy-$st-01-00000.$ppland.nc $refdirIC/${refcaseIC}.clm2.r.$yyyy-${st}-01-00000.nc
echo "${refcaseIC}.clm2.r.$yyyy-${st}-01-00000.nc" > $refdirIC/rpointer.lnd
ln -sf $IC_CLM_CPS_DIR1/$st/${CPSSYS}.hydros.r.$yyyy-$st-01-00000.$ppland.nc $refdirIC/${refcaseIC}.hydros.r.$yyyy-${st}-01-00000.nc
echo "${refcaseIC}.hydros.r.$yyyy-${st}-01-00000.nc" > $refdirIC/rpointer.rof

#-----------
ncpl=48
echo "timestep = $((86400 / $ncpl))"
echo "vertical levels 46"
stop_op=nmonths
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
./xmlchange GET_REFCASE=TRUE
if [[ $typeofrun == "hindcast" ]]
then
   ./xmlchange --subgroup case.checklist prereq=0
else
   ./xmlchange --subgroup case.checklist prereq=0
fi

#20240715 - test
#WE HAVE TRIED AND IT DOES NOT WORK REGARLESS THE FIGURE TESTED. THERE MUST BE A PROBLEM WITH THE INTERPRATATION OF VARIABLES FROM THE COMPILED LIBRARY
#./xmlchange PIO_NUMTASKS=4


sed -e "s/CASO/$caso/g;s/YYYY/$yyyy/g;s/mese/$st/g" $DIR_TEMPL/check_6months_output_in_archive.sh > $DIR_CASES/$caso/check_6months_output_in_archive_${caso}.sh
chmod u+x $DIR_CASES/$caso/check_6months_output_in_archive_${caso}.sh
outdirC3S=${WORK_C3S}/$yyyy$st/
sed -e "s:CASO:$caso:g;s:IC:$ic:g;s:OUTDIRC3S:$outdirC3S:g" $DIR_POST/nemo/interp_ORCA2_1X1_gridT2C3S_template.sh > $DIR_CASES/$caso/interp_ORCA2_1X1_gridT2C3S_${caso}.sh
chmod u+x $DIR_CASES/$caso/interp_ORCA2_1X1_gridT2C3S_${caso}.sh
sed -e "s:CASO:$caso:g;s:ICs:$ic:g;s:OUTDIRC3S:$outdirC3S:g" $DIR_POST/cice/interp_cice2C3S_template.sh > $DIR_CASES/$caso/interp_cice2C3S_${caso}.sh
chmod u+x $DIR_CASES/$caso/interp_cice2C3S_${caso}.sh
sed -e "s:EXPNAME:$caso:g;s:DUMMYIC:$ic:g;" $DIR_TEMPL/postproc_monthly.sh > $DIR_CASES/$caso/postproc_monthly_${caso}.sh
chmod u+x $DIR_CASES/$caso/postproc_monthly_${caso}.sh
sed -e "s:EXPNAME:$caso:g;s:DUMMYIC:$ic:g;" $DIR_TEMPL/postproc_C3S.sh > $DIR_CASES/$caso/postproc_C3S_${caso}.sh
chmod u+x $DIR_CASES/$caso/postproc_C3S_${caso}.sh

mkdir -p $DIR_CASES/$caso/logs


#----------------------------------------------------------
# CAM  TEMPLATE
#----------------------------------------------------------
echo "IC CAM $ncdatanow"
sed -i '/ncdata/d' $DIR_CASES/$caso/user_nl_cam
echo "ncdata='$ncdatanow'">>$DIR_CASES/$caso/user_nl_cam

if [[ $yyyy$st -ge ${yyyySCEN}07 ]] && [[ $yyyy$st -le ${yyyySCEN}12 ]]
then
   echo "prescribed_ozone_file='ozone_strataero_WACCM_L70_zm5day_18500101-21010201_CMIP6histEnsAvg_SSP585_c240528.nc'">>$DIR_CASES/$caso/user_nl_cam
   echo "prescribed_strataero_file='ozone_strataero_WACCM_L70_zm5day_18500101-21010201_CMIP6histEnsAvg_SSP585_c240528.nc'">>$DIR_CASES/$caso/user_nl_cam
   echo "use_init_interp = .true.">>$DIR_CASES/$caso/user_nl_clm
fi
#for January 2015 the scenario compset is used here but for CLM ICs comes from historical one (last restart) 
if [[ $yyyy$st -eq 201501 ]]  
then   
   echo "use_init_interp = .true." >> $DIR_CASES/$caso/user_nl_clm
fi


#----------------------------------------------------------


cp $cesmexe $WORK_CPS/$caso/bld/cesm.exe

cd $DIR_CASES/$caso
#----------------------------------------------------------

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
set +euvx
    . $DIR_UTIL/condaactivation.sh
    condafunction activate $envcondacm3
set -euvx
    $DIR_CASES/$caso/case.submit
fi
checktime=`date`
echo 'run submitted ' $checktime
