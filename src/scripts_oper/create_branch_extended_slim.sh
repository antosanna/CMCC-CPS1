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
caso=${SPSSystem}ext_${yyyy}${st}_${nrun}
casoREST=${SPSSystem}_${yyyy}${st}_${nrun}
if [[ `whoami` == "$operational_user" ]]
then
   flag_test=0
fi

if [[ $machine == "leonardo" ]]
then
   module use -p $modpath
fi

if [[ $yyyy$st -ge ${yyyySCEN}07 ]]; then
   refcase=$refcaseSCEN
   DIR_NL=$DIR_TEMPL/sps4_user_nl/SSP585
else  #for hindcast period
   refcase=$refcaseHIST
   DIR_NL=$DIR_TEMPL/sps4_user_nl/HIST
fi
cesmexe=$DIR_EXE/cesm.exe.CPS1_${machine}
mkdir -p $DIR_CASES

ic='atm='$pp',lnd='$ppland',ocn='$poce''
#----------------------------------------------------------
#ncdatanow=$IC_CAM_CPS_DIR1/$st/${CPSSYS}.cam.i.$yyyy-$st-01-00000.$pp.nc
#----------------------------------------------------------
# clean everything
#----------------------------------------------------------
$DIR_UTIL/clean_caso.sh $caso
#----------------------------------------------------------
# create the case as a clone from the reference
#----------------------------------------------------------
# refcase changes with scenario but the executable must not
set +euvx
$DIR_CESM/cime/scripts/create_clone --case $DIR_CASES/$caso --clone $DIR_CASES/$refcase --cime-output-root $WORK_CPS

set -euvx
#----------------------------------------------------------
mkdir -p $DIR_CASES/$caso/logs
echo "$ic" > $DIR_CASES/$caso/logs/ic_${caso}.txt

cd $DIR_CASES/$caso
cp $DIR_NL/user_nl_cam_slim user_nl_cam
cp $DIR_NL/user_nl_clm_slim user_nl_clm
cp $DIR_NL/user_nl_cice .
cp $DIR_NL/user_nl_cpl .
cp $DIR_NL/user_nl_hydros .
cp $DIR_NL/user_nl_nemo .
#----------------------------------------------------------
# Copy log_cheker from DIR_TEMPL in $caso TO DO
#----------------------------------------------------------

rsync -av $DIR_TEMPL/env_workflow_sps4.xml_${env_workflow_tag} $DIR_CASES/$caso/env_workflow.xml
if [[ $machine == "leonardo" ]]
then
   rsync -av $DIR_TEMPL/env_mach_specific.xml_${env_workflow_tag} $DIR_CASES/$caso/env_mach_specific.xml
else
   if [[ $flag_dev -eq 1 ]]
   then
# this one submit without SC
      rsync -av $DIR_TEMPL/env_workflow_sps4.xml_${env_workflow_tag}_noSC $DIR_CASES/$caso/env_workflow.xml
   fi
fi

rsync -av $DIR_TEMPL/env_batch.xml_${env_workflow_tag} $DIR_CASES/$caso/env_batch.xml
# this makes use of SC and if a user has no access to the SC it cannot run
# TO DO
# set-up the case after modfication env_workflow
#----------------------------------------------------------
./case.setup --reset
./case.setup
./xmlchange BUILD_COMPLETE=TRUE
rsync -av $DIR_TEMPL/file_def_nemo-oce_slim.xml $DIR_CASES/$caso/Buildconf/nemoconf/file_def_nemo-oce.xml
rsync -av $DIR_TEMPL/field_def_nemo-oce.xml $DIR_CASES/$caso/Buildconf/nemoconf/
#----------------------------------------------------------
# CESM2.1 can use a refdir where to find all the needed restarts
# IC_NEMO_CPS_DIR and IC_CICE_CPS_DIR will contain physical fields
if [[ "$USER" == "${operational_user}" ]]
then
   cd $SCRATCHDIR1/restarts4extended/$casoREST/rest
   restyyyy=$yyyy
   restmon=$((10#$st + $nmonfore ))
   if [[ $restmon -gt 12 ]]
   then
       restmon=0$(($restmon - 12))
       restyyyy=$(($yyyy + 1))
   elif [[ $restmon -lt 10 ]]
   then
       restmon=0$restmon
   fi
   if [[ -f $restyyyy-$restmon-01-00000.tar.gz ]]
   then
      gunzip $restyyyy-$restmon-01-00000.tar.gz
   fi
   refdirREST=$DIR_ARCHIVE/$casoREST/rest/$restyyyy-$restmon-01-00000
else
   restyyyy=$yyyy
   restmon=$((10#$st + $nmonfore ))
   if [[ $restmon -gt 12 ]]
   then
       restmon=0$(($restmon - 12))
       restyyyy=$(($yyyy + 1))
   elif [[ $restmon -lt 10 ]]
   then
       restmon=0$restmon
   fi
   mkdir -p $SCRATCHDIR/$casoREST/rest/
   if [[ -f $SCRATCHDIR1/restarts4extended/$casoREST/rest/$restyyyy-$restmon-01-00000.tar.gz ]]
   then
      rsync -auv $SCRATCHDIR1/restarts4extended/$casoREST/rest/$restyyyy-$restmon-01-00000.tar.gz $SCRATCHDIR/$casoREST/rest/
      gunzip $SCRATCHDIR/$casoREST/rest/$restyyyy-$restmon-01-00000.tar.gz
   else
      rsync -auv $SCRATCHDIR1/restarts4extended/$casoREST/rest/$restyyyy-$restmon-01-00000 $SCRATCHDIR/$casoREST/rest/
   fi   
   refdirREST=$SCRATCHDIR/$casoREST/rest/$restyyyy-$restmon-01-00000
fi

cd $DIR_CASES/$caso
#-----------
ncpl=48
echo "timestep = $((86400 / $ncpl))"
echo "vertical levels 46"
stop_op=nmonths
./xmlchange RUN_TYPE="branch"
./xmlchange RUN_STARTDATE=$yyyy-$st-01
./xmlchange RUN_REFDATE=$restyyyy-$restmon-01
./xmlchange RUN_REFCASE=${casoREST}
./xmlchange RUN_REFDIR=${refdirREST}
./xmlchange STOP_OPTION=$stop_op
./xmlchange REST_OPTION=$stop_op
./xmlchange RESUBMIT=$(($nmonforext - 1))
./xmlchange ATM_NCPL=$ncpl
./xmlchange INFO_DBUG=0
./xmlchange NEMO_REBUILD=TRUE  
./xmlchange GET_REFCASE=TRUE
if [[ $machine == "cassandra" ]]
then
   ./xmlchange PIO_STRIDE_ATM=16
   ./xmlchange PIO_STRIDE_LND=16
   ./xmlchange PIO_STRIDE_ROF=16
   ./xmlchange PIO_STRIDE_ICE=16
   
   ./xmlchange PIO_NUMTASKS_ATM=21
   ./xmlchange PIO_NUMTASKS_LND=21
   ./xmlchange PIO_NUMTASKS_ROF=21
   ./xmlchange PIO_NUMTASKS_ICE=21
fi

if [[ $typeofrun == "hindcast" ]]
then
   ./xmlchange --subgroup case.checklist prereq=0
else
   ./xmlchange --subgroup case.checklist prereq=1
fi

sed -e "s/CASO/$caso/g;s/YYYY/$yyyy/g;s/mese/$st/g;s/member/$nrun/g" $DIR_TEMPL/check_10ext_months_output_in_archive.sh > $DIR_CASES/$caso/check_10ext_months_output_in_archive_${caso}.sh
chmod u+x $DIR_CASES/$caso/check_10ext_months_output_in_archive_${caso}.sh
outdirC3SEXT=${WORK_C3SEXT}/$yyyy$st/
sed -e "s:CASO:$caso:g;s:IC:$ic:g;s:OUTDIRC3S:$outdirC3SEXT:g" $DIR_POST/nemo/interp_ORCA2_1X1_gridT2C3S_template.sh > $DIR_CASES/$caso/interp_ORCA2_1X1_gridT2C3Sext_${caso}.sh
chmod u+x $DIR_CASES/$caso/interp_ORCA2_1X1_gridT2C3Sext_${caso}.sh
sed -e "s:CASO:$caso:g;s:ICs:$ic:g;s:OUTDIRC3S:$outdirC3SEXT:g" $DIR_POST/cice/interp_cice2C3S_template.sh > $DIR_CASES/$caso/interp_cice2C3Sext_${caso}.sh
chmod u+x $DIR_CASES/$caso/interp_cice2C3Sext_${caso}.sh
sed -e "s:EXPNAME:$caso:g;s:DUMMYIC:$ic:g;" $DIR_TEMPL/postproc_monthly.sh > $DIR_CASES/$caso/postproc_monthly_${caso}.sh
chmod u+x $DIR_CASES/$caso/postproc_monthly_${caso}.sh
sed -e "s:EXPNAME:$caso:g;s:DUMMYIC:$ic:g;" $DIR_TEMPL/postproc_C3Sext.sh > $DIR_CASES/$caso/postproc_C3Sext_${caso}.sh
chmod u+x $DIR_CASES/$caso/postproc_C3Sext_${caso}.sh

mkdir -p $DIR_CASES/$caso/logs


#----------------------------------------------------------
# CAM  TEMPLATE
#----------------------------------------------------------
#echo "IC CAM $ncdatanow"
#sed -i '/ncdata/d' $DIR_CASES/$caso/user_nl_cam
#echo "ncdata='$ncdatanow'">>$DIR_CASES/$caso/user_nl_cam
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
#in forecast mode CLM ICs comes from an interrupted run covering the previous month
#so, for january the CLM IC report a date from december of the previous year.
#this happens as we produce the IC on the 1st of the month - due to the latency of the EDA data
if [[ ${st} -eq 01 ]] && [[ $typeofrun == "forecast" ]]
then
    echo "check_finidat_year_consistency = .false. " >> $DIR_CASES/$caso/user_nl_clm
fi
#----------------------------------------------------------
cp $DIR_TEMPL/user_nl_hydros $DIR_CASES/$caso/

cp $cesmexe $WORK_CPS/$caso/bld/cesm.exe

cd $DIR_CASES/$caso

if [[ $flag_test -eq 0 ]]
then
set +euvx
    . $DIR_UTIL/condaactivation.sh
    condafunction activate $envcondacm3
set -euvx
    $DIR_CASES/$caso/case.submit
fi
checktime=`date`
echo 'run submitted ' $checktime
