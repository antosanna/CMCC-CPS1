#!/bin/sh -l
#BSUB -q s_long
#BSUB -J SPS3.5_IC4CAM
#BSUB -e logs/SPS3.5_IC4CAM_%J.err
#BSUB -o logs/SPS3.5_IC4CAM_%J.out

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_SPS35}/descr_SPS3.5.sh
. ${DIR_TEMPL}/load_nco

set -euvx
#----------------------------------------------------------
# get from the parent script start-date and perturbations
#----------------------------------------------------------
yyin=$1
mmin=$2
ddin=$3
startdate=$4
tstamp=$5
pp=$6
ppland=$7
caso=$8
ncpl=$9
stopdate=${10}    #THIS IS NOT USED MUST BE REMOVED
bk=${11}
ncdata=${12}
ICfile=${13}
if [ $bk -ne 0 ]
then
   bkoce=${14}
   bkice=${15}
   bkclm=${16}
   bkrtm=${17}
fi
#------------------------------------------------------------
st=`echo $startdate|cut -c 5-6`
yyyy=`echo $startdate|cut -c 1-4`
set +euvx
if [ $yyyy -lt ${iniy_fore} ]
then
   . ${DIR_SPS35}/descr_hindcast.sh
else
   . ${DIR_SPS35}/descr_forecast.sh
fi
set -euvx
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
if [ $yyyy -le ${endy_hind} ]
then
   p=1
else
   p=9       # UNPERTURBED
fi
poce=`printf '%.2d' $p`
#
today=`date +%Y%m`
yynemo=`echo $today|cut -c 1-4`
stnemo=`echo $today|cut -c 5-6`

refcase=${SPSSYS}_guess2CAM_IC_XXTR_nospike
cesmexe=$DIR_EXE1/cesm.exe.guess2CAM_IC_ne60np4L46_XXTR_nospike
if [ $yyyy -eq 2014 -a $((10#$st)) -ge 7 ] || [ $yyyy -ge 2015 ]; then
   refcase=${SPSSYS}_guess2CAM_IC_RCP8.5_nospike
   cesmexe=$DIR_EXE1/cesm.exe.guess2CAM_IC_ne60np4L46_RCP8.5_nospike
fi
#
#----------------------------------------------------------
# clean everything
#----------------------------------------------------------
if [ -d $WORK_SPS3/$caso ]
then
    cd $WORK_SPS3/
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
cd $DIR_CESM/scripts
./create_clone -case $DIR_CASES/$caso -clone $DIR_CASES1/$refcase
#----------------------------------------------------------
mkdir -p $DIR_CASES/$caso/logs
cd $DIR_CASES/$caso
#----------------------------------------------------------
# Copy log_cheker from DIR_TEMPL in $caso
#----------------------------------------------------------
cp ${DIR_TEMPL}/log_checker_launcher.sh $DIR_CASES/$caso/log_checker_launcher.sh
cp ${DIR_TEMPL}/log_checker.sh $DIR_CASES/$caso/log_checker.sh
sed -i "s:ICTOBECHANGEDBYSED:$ncdata:g" $DIR_CASES/$caso/log_checker.sh
sed "s:CASO:$caso:g" $DIR_TEMPL/change_timestep.sh > $DIR_CASES/$caso/change_timestep.sh
chmod u+x $DIR_CASES/$caso/change_timestep.sh
#----------------------------------------------------------
# Copy modified mkbatch.${machine} from DIR_TEMPL in Tools
#----------------------------------------------------------
sed "s/\-q p_long/\-q p_medium/g;s/\-W 3/\-W 2/g" ${DIR_TEMPL}/mkbatch.${SPSSYS}.${machine} > $DIR_CASES/$caso/Tools/mkbatch.${machine}
sed -e "s:APPRUN:$apprun:g;s:SLAID:$slaID:g;s:PID:$pID:g" ${DIR_TEMPL}/mkbatch.${SPSSYS}.$machine > $DIR_CASES/$caso/Tools/mkbatch.$machine
#----------------------------------------------------------
# Copy modified cesm_postrun_setup_${SPSSYS}guess
#----------------------------------------------------------
cp ${DIR_TEMPL}/cesm_postrun_setup_${SPSSYS}guess $DIR_CASES/$caso/Tools/cesm_postrun_setup
#----------------------------------------------------------
# set-up the case
#----------------------------------------------------------
./cesm_setup
#----------------------------------------------------------
# this modify the env_build.xml to tell the model that it has already been compiled an to skip the building-up (taking more than 30')
#----------------------------------------------------------
./xmlchange -file env_build.xml -id BUILD_COMPLETE -val TRUE
./xmlchange -file env_build.xml -id BUILD_STATUS -val 0

cd $DIR_CASES/$caso
echo "inithist = 'ENDOFRUN'" >>user_nl_cam

#----------------------------------------------------------
# CAM  IC $IC_SPS_guess/CAM
#----------------------------------------------------------
cat > user_nl_cam << EOF4
ncdata="$ncdata"
inithist = 'ENDOFRUN'
nhtfrq = -6
cldwat_icritc=  18.0e-6,
hkconv_c0=  1.0e-4,
uwshcu_rpen=5.0
nu           =  1.0e14
nu_div       =  2.5e14
nu_p         =  1.e14
rsplit       =  4
qsplit       =  4
tms_z0fac    =  0.1875
EOF4
yyst=`echo $startdate|cut -c 1-4`
if [ $bk -eq 0 ]
then
   ic_clm=$IC_CLM_SPS_DIR/$st/land_clm45_forced_${ppland}_analisi_1993_2015.clm2.r.$yyst-$st-01-00000.nc
   if [ -f $ic_clm.gz ] 
   then 
     if [ `whoami` == $operational_user ]
      then
        gunzip $ic_clm.gz
      else
        title="[CAMIC] ${SPSSYS} ERROR"
        body="$ic_clm file is compressed and you do not have permission to do gunzip. Exit and do it manually"
        $DIR_SPS35/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes"
        exit
     fi
   fi
   echo "IC CLM $ic_clm"
   ln -sf $ic_clm $WORK_SPS3/$caso/run/$refcase.clm2.r.$yyin-$mmin-$ddin-00000.nc
   ic_rtm=$IC_CLM_SPS_DIR/$st/land_clm45_forced_${ppland}_analisi_1993_2015.rtm.r.$yyst-$st-01-00000.nc
   if [ -f $ic_rtm.gz ] 
   then
      if [ `whoami` == $operational_user ]
      then
        gunzip $ic_rtm.gz
      else
        title="[CAMIC] ${SPSSYS} ERROR"
        body="$ic_rtm file is compressed and you do not have permission to do gunzip. Exit and do it manually"
        $DIR_SPS35/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes"
        exit
      fi
   fi
   echo "IC RTM $ic_rtm"
   ln -sf $ic_rtm $WORK_SPS3/$caso/run/$refcase.rtm.r.$yyst-$st-01-00000.nc

   echo "$refcase.clm2.r.$yyin-$mmin-$ddin-00000.nc" > $WORK_SPS3/$caso/run/rpointer.lnd
   echo "$refcase.rtm.r.$yyin-$mmin-$ddin-00000.nc" > $WORK_SPS3/$caso/run/rpointer.rof
else
   ic_clm=$bkclm
   if [ -f $ic_clm.gz ] 
   then
      if [ `whoami` == $operational_user ]
      then
        gunzip $ic_clm.gz
      else
        title="[CAMIC] ${SPSSYS} ERROR"
        body="$ic_clm file is compressed and you do not have permission to do gunzip. Exit and do it manually"
        $DIR_SPS35/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes"
        exit
      fi
   fi
   ic_rtm=$bkrtm
   if [ -f $ic_rtm.gz ] 
   then 
      if [ `whoami` == $operational_user ]
      then
        gunzip $ic_rtm.gz
      else
        title="[CAMIC] ${SPSSYS} ERROR"
        body="$ic_rtm file is compressed and you do not have permission to do gunzip. Exit and do it manually"
        $DIR_SPS35/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes"
        exit
     fi
   fi
   echo "IC CLM $ic_clm"
   ln -sf $ic_clm $WORK_SPS3/$caso/run/$refcase.clm2.r.$yyin-$mmin-$ddin-00000.nc
   echo "IC RTM $ic_rtm"
   ln -sf $ic_rtm $WORK_SPS3/$caso/run/$refcase.rtm.r.$yyst-$st-01-00000.nc

   echo "$refcase.clm2.r.$yyin-$mmin-$ddin-00000.nc" > $WORK_SPS3/$caso/run/rpointer.lnd
   echo "$refcase.rtm.r.$yyin-$mmin-$ddin-00000.nc" > $WORK_SPS3/$caso/run/rpointer.rof
fi

#----------------------------------------------------------
# Nemo
#----------------------------------------------------------
if [ $bk -eq 0 ]
then
   nemoin=${IC_NEMO_SPS_DIR}/${st}/${yyst}${st}0100_R025_${poce}_restart_oce_modified.nc
   if [ -f $nemoin.gz ] 
   then
      if [ `whoami` == $operational_user ]
      then
        gunzip $nemoin.gz
      else
        title="[CAMIC] ${SPSSYS} ERROR"
        body="$nemoin file is compressed and you do not have permission to do gunzip. Exit and do it manually"
        $DIR_SPS35/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes"
        exit
      fi
   fi
   cicein=${IC_NEMO_SPS_DIR}/${st}/ice_ic${yyst}${st}_${poce}.nc
   if [ -f $cicein.gz ] 
   then
      if [ `whoami` == $operational_user ]
      then
        gunzip $cicein.gz
      else
        title="[CAMIC] ${SPSSYS} ERROR"
        body="$cicein file is compressed and you do not have permission to do gunzip. Exit and do it manually"
        $DIR_SPS35/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes"
        exit
      fi
   fi
   if [ ! -f  $nemoin ]
   then
# JUST IN CASE UNPERTURBED DOES NOT EXHIST TAKE MEMBER 1
      poce=01
      nemoin=${IC_NEMO_SPS_DIR}/${st}/${yyst}${st}0100_R025_${poce}_restart_oce_modified.nc
   fi   
   echo "IC Nemo $nemoin"
   echo "IC Cice $cicein"
else
   nemoin=$bkoce
   if [ -f $nemoin.gz ] 
   then
      if [ `whoami` == $operational_user ]
      then
        gunzip $nemoin.gz
      else
        title="[CAMIC] ${SPSSYS} ERROR"
        body="$nemoin file is compressed and you do not have permission to do gunzip. Exit and do it manually"
        $DIR_SPS35/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes"
        exit
      fi
   fi
   echo "IC Nemo $nemoin"
   cicein=${bkice}
   if [ -f $cicein.gz ] 
   then
      if [ `whoami` == $operational_user ]
      then
        gunzip $cicein.gz
      else
        
        title="[CAMIC] ${SPSSYS} ERROR"
        body="$cicein file is compressed and you do not have permission to do gunzip. Exit and do it manually"
        $DIR_SPS35/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "yes"
        exit
      fi
   fi
   echo "IC Cice ${cicein}"
fi
ln -sf $nemoin $WORK_SPS3/$caso/run/${refcase}_00000320_restart.nc
ln -sf $cicein $WORK_SPS3/$caso/run/ice_ic.nc
#
echo "timestep = $((86400 / $ncpl))"
echo "vertical levels 46"
#----------------------------------------------------------
# define the first month run as hybrid
#----------------------------------------------------------
./xmlchange -file env_run.xml -id PIO_TYPENAME -val pnetcdf
./xmlchange -file env_run.xml -id RUN_TYPE -val hybrid
./xmlchange -file env_run.xml -id RUN_STARTDATE -val $yyin-$mmin-$ddin
./xmlchange -file env_run.xml -id RUN_REFDATE -val $yyin-$mmin-$ddin
./xmlchange -file env_run.xml -id RUN_REFCASE -val ${refcase}
./xmlchange -file env_run.xml -id STOP_OPTION -val nday
./xmlchange -file env_run.xml -id STOP_DATE -val $startdate
./xmlchange -file env_run.xml -id STOP_N -val $diff
./xmlchange -file env_run.xml -id DOUT_L_MS -val TRUE
./xmlchange -file env_run.xml -id CLM_BLDNML_OPTS -val "-clm_start_type 'arb_ic'"
./xmlchange -file env_run.xml -id CONTINUE_RUN -val FALSE
./xmlchange -file env_run.xml -id RESUBMIT -val 0
./xmlchange -file env_run.xml -id REST_OPTION -val $\STOP_OPTION
./xmlchange -file env_run.xml -id REST_N -val $\STOP_N
./xmlchange -file env_run.xml -id ATM_NCPL -val $ncpl
./xmlchange -file env_run.xml -id OCN_NCPL -val 16
./xmlchange -file env_run.xml -id ROF_NCPL -val $\ATM_NCPL
./xmlchange -file env_run.xml -id INFO_DBUG -val 0
./xmlchange -file env_run.xml -id NEMO_REBUILD -val TRUE

cp $cesmexe $WORK_SPS3/$caso/bld/cesm.exe
cp -r $DIR_EXE1/ocn_guess/* $WORK_SPS3/$caso/bld/ocn/

cd $DIR_CASES/$caso
#----------------------------------------------------------
# add the notification on error to the job script
#----------------------------------------------------------
#sed -i "s/"p_long"/"p_medium"/g" $DIR_CASES/$caso/$caso.run
chmod u+x $caso.run
#----------------------------------------------------------
# create compress_IC.sh 
#----------------------------------------------------------
sed "s:YYIN:$yyin:g;s:MMIN:$mmin:g;s:DDIN:$ddin:g;s:STARTDATE:$startdate:g;s:TSTAMP:$tstamp:g;s:PP:$pp:g;s:OUTFILE:$ICfile:g;s:NCATA:$ncdata:g" $DIR_TEMPL/compress_IC_template_op.sh >$DIR_CASES/$caso/compress_IC.sh
chmod u+x compress_IC.sh
#----------------------------------------------------------
# submit first month
#----------------------------------------------------------
totcores=`./xmlquery TOTALPES | awk '{print $4}'`
pes_per_node=`./xmlquery PES_PER_NODE | awk '{print $4}'`
RUNSTAT=`./xmlquery RUNSTAT | awk '{print $4}'`
#${DIR_SPS35}/submitcommand_IC.sh -m $machine -S qos_resv -t "4" -q $parallelq_m -f yes -n $totcores -R ${pes_per_node} -j ${caso}_run -l $DIR_CASES/$caso/ -d $DIR_CASES/$caso -s $caso.run
${DIR_SPS35}/submitcommand.sh -m $machine -q $parallelq_m -t "4" -S qos_resv -f yes -n $totcores -R ${pes_per_node} -j ${caso}_run -l $DIR_CASES/$caso/ -d $DIR_CASES/$caso -s $caso.run
checktime=`date`
echo 'run submitted ' $checktime

