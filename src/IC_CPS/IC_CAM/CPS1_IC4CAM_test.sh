#!/bin/sh -l

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
ppland=$5
caso=$6
ncpl=$7
bk=$8
ncdata=$9
ICfile=${10}
refdir_refcase_rest=/work/csp/cp1/restart_cps_test/$caso
mkdir -p $refdir_refcase_rest
refcase_rest=cm3_cam122_cpl2000-bgc_t01  #to be defined
refdate_rest=0020-01-01  #to be defined
if [ $bk -ne 0 ]
then
   bkoce=${11}
   bkice=${12}
   bkclm=${13}
   bkrtm=${14}
   repo_rest=/work/csp/as34319/restart_cps_test/0020-01-01-00000
   refcase_rest=cm3_cam122_cpl2000-bgc_t01
   refdate_rest=0020-01-01
   refdate_rest_nemo=`echo ${refdate_rest:0:4}${refdate_rest:5:2}${refdate_rest:8:2}`
fi
#------------------------------------------------------------
st=`echo $startdate|cut -c 5-6`
yyyy=`echo $startdate|cut -c 1-4`
# --------------------------------------------
# NOW REMOVE 29/2 AS STARTDATE  (CAM CALENDAR NOLEAP)
# --------------------------------------------
if [ $((10#$mmin)) -eq 2 ] && [ $ddin -eq 29 ]
then
   ddin=28
fi
# --------------------------------------------
# NOW REMOVE 29/2 AS STARTDATE  (CAM CALENDAR NOLEAP)  -
# --------------------------------------------

diff=`${DIR_UTIL}/datediff.sh $startdate $yyin$mmin$ddin`
p=0
poce=`printf '%.2d' $p`
#
today=`date +%Y%m`
yynemo=`echo $today|cut -c 1-4`
stnemo=`echo $today|cut -c 5-6`

# for SPS4 exactly should be the same
#refcase=${CPSSYS}_guess2CAM_IC_XXTR
# will be but now use 2000 continuous refcase=${CPSSYS}_XXTR
refcase=SPS4_HIST_hyb_refcase
#cesmexe=$DIR_EXE1/cesm.exe.guess2CAM_IC_V0.47x0.63_L83_XXTR
# WILL BE A MODULE
cesmexe=$WORK_CPS/$refcase/bld/cesm.exe
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
# create the case as a clone from the reference
#----------------------------------------------------------
#./create_clone --case $DIR_CASES/$caso --clone $DIR_CASES1/$refcase --cime-output-root /work/$DIVISION/$USER/CMCC-CM
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
#----------------------------------------------------------
# CHECK IF NEEDED IN SPS4
#----------------------------------------------------------
#sed "s/\-q p_long/\-q p_medium/g;s/\-W 3/\-W 2/g" ${DIR_TEMPL}/mkbatch.${CPSSYS}.${machine} > $DIR_CASES/$caso/Tools/mkbatch.${machine}
#sed -e "s:APPRUN:$apprun:g;s:SLAID:$slaID:g;s:PID:$pID:g" ${DIR_TEMPL}/mkbatch.${CPSSYS}.$machine > $DIR_CASES/$caso/Tools/mkbatch.$machine
# THIS WILL BE DONE THROUGH BATCH_COMMAND_FLAGS
#----------------------------------------------------------
# Copy modified cesm_postrun_setup_${CPSSYS}guess
#----------------------------------------------------------
#cp ${DIR_TEMPL}/cesm_postrun_setup_${CPSSYS}guess $DIR_CASES/$caso/Tools/cesm_postrun_setup
# VERIFY IF STILL NEEDED
rsync -av $DIR_TEMPL/env_workflow_IC_cam.xml $DIR_CASES/$caso/env_workflow.xml
#----------------------------------------------------------
# set-up the case
#----------------------------------------------------------
./case.setup
#----------------------------------------------------------
# this modify the env_build.xml to tell the model that it has already been compiled an to skip the building-up (taking more than 30')
#----------------------------------------------------------
./xmlchange BUILD_COMPLETE=TRUE
./xmlchange BUILD_STATUS=0

cd $DIR_CASES/$caso

#----------------------------------------------------------
# CAM  IC $IC_SPS_guess/CAM
#----------------------------------------------------------
# QUESTA PARTE ANCORA DA DEFINIRE!!!
#do this through sed 
#cat > user_nl_cam << EOF4
#echo "ncdata=$ncdata">>$DIR_CASES
#inithist = 'ENDOFRUN'
#nhtfrq = -6
#EOF4
yyyy=`echo $startdate|cut -c 1-4`
if [ $bk -eq 0 ]
then
# TO BE MODIFIED
   ic_clm=$IC_CLM_CPS_DIR1/$st/land_clm45_forced_${ppland}_analisi_1993_2015.clm2.r.$yyyy-$st-01-00000.nc
   if [ -f $ic_clm.gz ] 
   then 
     if [ `whoami` == $operational_user ]
      then
        gunzip $ic_clm.gz
      else
        mkdir -p $IC_CLM_CPS_DIR/$st
        ic_clm=$IC_CLM_CPS_DIR/$st/land_clm45_forced_${ppland}_analisi_1993_2015.clm2.r.$yyyy-$st-01-00000.nc
        cp $IC_CLM_CPS_DIR1/$st/land_clm45_forced_${ppland}_analisi_1993_2015.clm2.r.$yyyy-$st-01-00000.nc.gz $IC_CLM_CPS_DIR/$st
        gunzip $ic_clm.gz
        title="[CAMIC] ${CPSSYS} notification"
        body="$ic_clm has been copied from $operational_user to $USER directory"
        $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
     fi
   fi
   echo "IC CLM $ic_clm"
   ic_rtm=$IC_CLM_CPS_DIR1/$st/land_clm45_forced_${ppland}_analisi_1993_2015.rtm.r.$yyyy-$st-01-00000.nc
   if [ -f $ic_rtm.gz ] 
   then
      if [ `whoami` == $operational_user ]
      then
        gunzip $ic_rtm.gz
      else
        mkdir -p $IC_CLM_CPS_DIR/$st
        ic_rtm=$IC_CLM_CPS_DIR/$st/land_clm45_forced_${ppland}_analisi_1993_2015.rtm.r.$yyyy-$st-01-00000.nc
        cp $IC_CLM_CPS_DIR1/$st/land_clm45_forced_${ppland}_analisi_1993_2015.rtm.r.$yyyy-$st-01-00000.nc.gz $IC_CLM_CPS_DIR/$st/
        gunzip $ic_rtm.gz
        title="[CAMIC] ${CPSSYS} notification"
        body="$ic_rtm has been copied from $operational_user to $USER"
        $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
      fi
   fi
   echo "IC RTM $ic_rtm"

   echo "$ic_clm" > $WORK_CPS/$caso/run/rpointer.lnd
   echo "$ic_rtm" > $WORK_CPS/$caso/run/rpointer.hydros
else
   ic_clm=$bkclm
   if [ -f $ic_clm.gz ] 
   then
        gunzip $ic_clm.gz
   fi
   ic_rtm=$bkrtm
   if [ -f $ic_rtm.gz ] 
   then 
        gunzip $ic_rtm.gz
   fi
   echo "IC CLM $ic_clm"
   echo "IC RTM $ic_rtm"

   echo "$ic_rtm" > $WORK_CPS/$caso/run/rpointer.hydros
fi
   ln -sf $ic_clm $refdir_refcase_rest/$refcase_rest.clm2.r.$refdate_rest-00000.nc
   echo $refcase_rest.clm2.r.$refdate_rest-00000.nc >$refdir_refcase_rest/rpointer.lnd
   ln -sf $ic_rtm $refdir_refcase_rest/$refcase_rest.hydros.r.$refdate_rest-00000.nc
   echo $refcase_rest.hydros.r.$refdate_rest-00000.nc > $refdir_refcase_rest/rpointer.hydros
   echo $refcase_rest.cice.r.$refdate_rest-00000.nc > $refdir_refcase_rest/rpointer.ice
#   ln -sf $ic_nemo $refdir_refcase_rest/${refcase_rest}_${refdate_rest_nemo}_restart.nc

#----------------------------------------------------------
# Nemo
# anche qui le IC vanno messe tutte in una directory che sara' refdir e poi prese con GET_REFCASE
#----------------------------------------------------------
if [[ $bk -eq 0 ]]
then
   nemoin=${IC_NEMO_CPS_DIR1}/${st}/${CPSSYS}.$poce.${yyyy}${st}01_restart.nc
   if [ -f $nemoin.gz ] 
   then
      if [ $USER == $operational_user ]
      then
        gunzip $nemoin.gz
        ln -sf $nemoin $refdir_refcase/${refcase}_restart.nc
      else
        mkdir -p ${IC_NEMO_CPS_DIR}/${st}
        nemoin=${IC_NEMO_CPS_DIR}/${st}/${CPSSYS}.$poce.${yyyy}${st}01_restart.nc
        cp ${IC_NEMO_CPS_DIR1}/${st}/${CPSSYS}.$poc${CPSSYS}.$pocee${yyyy}${st}01_restart.nc.gz ${IC_NEMO_CPS_DIR}/${st}/
        gunzip $nemoin.gz
        title="[CAMIC] ${CPSSYS} notification"
        body="$nemoin has been copied from $operational_user to $USER"
        $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" 
      fi
   fi
# ADD PERTURBATION TO CICE
   cicein=${IC_NEMO_CPS_DIR1}/${st}/${CPSSYS}.$poce.cice.r.$yyyy-$st-01-00000.nc
   if [ -f $cicein.gz ] 
   then
      if [ `whoami` == $operational_user ]
      then
        gunzip $cicein.gz
      else
        mkdir -p ${IC_NEMO_CPS_DIR}/${st}
# ADD PERTURBATION TO CICE
        cicein=${IC_NEMO_CPS_DIR}/${st}/${CPSSYS}.$poce.cice.r.$yyyy-$st-01-00000.nc
        cp ${IC_NEMO_CPS_DIR1}/${st}/${CPSSYS}.$poce.cice.r.$yyyy-$st-01-00000.nc.gz ${IC_NEMO_CPS_DIR}/${st}/
        gunzip $cicein.gz
        title="[CAMIC] ${CPSSYS} notification"
        body="$cicein file has been copied from $operational_user to $USER"
        $DIR_UTIL/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
      fi
   fi
   echo "IC Nemo $nemoin"
   echo "IC Cice $cicein"
else
# backup
   nemoin=$bkoce
   if [ -f $nemoin.gz ] 
   then
        gunzip $nemoin.gz
   fi
   echo "IC Nemo $nemoin"
   cicein=${bkice}
   if [ -f $cicein.gz ] 
   then
        gunzip $cicein.gz
   fi
   echo "IC Cice ${cicein}"
fi
#if [[ $bk -eq 0 ]]
#then
# qui modificare anche qui con $refdirIC
   ln -sf $nemoin $WORK_CPS/$caso/run/${refcase_rest}_restart.nc
   ln -sf $cicein $WORK_CPS/$caso/run/$refcase_rest.cice.r.$refdate_rest-00000.nc
#else
#   ln -sf $nemoin $WORK_CPS/$caso/run/${clmref}_restart.nc
#   ln -sf $cicein $WORK_CPS/$caso/run/$clmref.cice.r.$clmrefdate-00000.nc
#fi
#
echo "timestep = $((86400 / $ncpl))"
echo "vertical levels 86"
#----------------------------------------------------------
# define the first month run as hybrid
#----------------------------------------------------------
./xmlchange RUN_STARTDATE=$yyin-$mmin-$ddin
if [[ $bk -eq 1 ]]
then
   ./xmlchange RUN_REFCASE=$refcase_rest
   ./xmlchange RUN_REFDATE=$refdate_rest
   ./xmlchange RUN_REFDIR=$refdir_refcase_rest
else
   ./xmlchange RUN_REFDATE=$yyin-$mmin-$ddin
   ./xmlchange RUN_REFCASE=${refcase}
fi
./xmlchange STOP_OPTION=ndays
./xmlchange STOP_DATE=$startdate
./xmlchange STOP_N=$diff
./xmlchange ATM_NCPL=$ncpl

# AL MOMENTO NON CI SONO
cp $cesmexe $WORK_CPS/$caso/bld/cesm.exe
#cp -r $DIR_EXE1/ocn_guess/* $WORK_CPS/$caso/bld/ocn/

cd $DIR_CASES/$caso
#----------------------------------------------------------
# VEDERE SE NECESSARIO create compress_IC.sh 
#----------------------------------------------------------
#sed "s:YYIN:$yyin:g;s:MMIN:$mmin:g;s:DDIN:$ddin:g;s:STARTDATE:$startdate:g;s:TSTAMP:$tstamp:g;s:PP:$pp:g;s:OUTFILE:$ICfile:g;s:NCATA:$ncdata:g" $DIR_TEMPL/compress_IC_template_op.sh >$DIR_CASES/$caso/compress_IC.sh
#chmod u+x compress_IC.sh
#----------------------------------------------------------
# submit first month
#----------------------------------------------------------
totcores=`./xmlquery TOTALPES | awk '{print $4}'`
echo "inithist = 'ENDOFRUN'" >>user_nl_cam
./case.submit
checktime=`date`
echo 'run submitted ' $checktime

