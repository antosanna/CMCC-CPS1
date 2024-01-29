#!/bin/sh -l
set -a
mymail=sp1@cmcc.it
#mymail=antonella.sanna@cmcc.it
#mymail=andrea.borrelli@cmcc.it
#ncheck=`grep Juno /etc/mtab|wc -l`
#ncheckbackup=`grep marconi /etc/mtab|wc -l`
#if [[ $ncheckbackup -ne 0 ]]
#then
#   machine="marconi"
#elif [[ $ncheck -ne 0 ]]
#then
if [[ -n `echo $PS1|grep marconi` ]]
then
   machine="marconi"
elif [[ -n `echo $PS1|grep juno` ]]
then
   machine="juno"
   alias rm="rm -f"
   alias cp="/bin/cp -f"
   alias mv="mv -f"
elif [[ -n `echo $PS1|grep zeus` ]]
then
   machine="zeus"
else
   echo "MACHINE UNKNOWN!! EXITING NOW!!"
   exit -1
fi
SPSSystem=sps4
DPSSystem=dps3
CPSSYS=CPS1
yyyySCEN=2015
refcaseHIST=${CPSSYS}_HIST_reference
refcaseSCEN=${CPSSYS}_SCEN_reference
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Machine dependent vars
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [[ "$machine" == "juno" ]] || [[ "$machine" == "zeus" ]]
then
   MYCESMDATAROOT=/data/$DIVISION/$USER/
   nmax_lt_arch_md=15   #in SPS3.5 15 lt_archive_C3S_moredays occupy ~ 1TB
   envcondanemo=nemo_rebuild
   if [[ $machine == "juno" ]]
   then
      operational_user=cp1
      pID=0490 #Juno
#      pID=0438 #Juno
      cores_per_node=72
      nnodes_SC=56
      cores_per_run=288
      mpilib4py_nemo_rebuild=impi-2021.6.0/2021.6.0
      mpirun4py_nemo_rebuild=mpiexec.hydra
      envcondarclone=rclone_gdrive
      envcondaclm=postpc_CLM_C3S
      envcondacm3=cmcc-cm_py39
      maxnumbertosubmit=18
      maxnumberguarantee=14
      env_workflow_tag=cmcc
      DIR_REST_OIS=/work/csp/aspect/CESM2/rea_archive/
   elif [[ $machine == "zeus" ]]
   then
      pID=0574 #zeus
      #pID=0438 #zeus
      nnodes_SC=120
      cores_per_node=36
      cores_per_run=720
      operational_user=sps-dev
      maxnumbertosubmit=10
      maxnumberguarantee=6
      mpilib4py_nemo_rebuild=impi20.1/19.7.217
      mpirun4py_nemo_rebuild=mpirun
      envcondaclm=/work/csp/sp1/anaconda3/envs/CMOR_5
      envcondacm3=/users_home/csp/dp16116/.conda/envs/py38CS2
      env_workflow_tag=cmcc
   fi
# TEMPORARY +
   DIR_NEMO_REBUILD=$DIR_CESM/components/nemo/source/utils/py_nemo_rebuild/src/py_nemo_rebuild/
# TEMPORARY -
   WORK=/work/$DIVISION/$USER/
   WORK1=/work/$DIVISION/$operational_user/
#   S_apprun=??? #SERIAL_sps35 Zeus
#now suppressed because redundant
#   sla_serialID=SC_SERIAL_sps35 #Zeus
   BATCHRUN="RUN"
   BATCHPEND="PEND"
   nmb_nemo_domains=279
   nmb_nemo_dmofiles=48 #8 files for each month
# queues Juno
   serial_test=s_long
   serialq_s=s_short
   serialq_m=s_medium
   time_limit_serialq_m_min=`bqueues -l $serialq_m|grep min|awk '{print $1}'|cut -d '.' -f1`   #RUNLIMIT TIME IN min
   time_limit_serialq_m=$((time_limit_serialq_m_min / 60 )) ##RUNLIMIT TIME IN hours
   parallelq_s=p_short
   time_limit_parallelq_s_min=`bqueues -l $parallelq_s|grep min|awk '{print $1}'|cut -d '.' -f1`   #RUNLIMIT TIME IN min
   time_limit_parallelq_s=$((time_limit_parallelq_s_min / 60 )) ##RUNLIMIT TIME IN hours
   parallelq_m=p_medium
   time_limit_parallelq_m_min=`bqueues -l $parallelq_m|grep min|awk '{print $1}'|cut -d '.' -f1`   #RUNLIMIT TIME IN min
   time_limit_parallelq_m=$((time_limit_parallelq_m_min / 60 )) ##RUNLIMIT TIME IN hours
   parallelq_l=p_long
   time_limit_parallelq_l_min=`bqueues -l $parallelq_l|grep min|awk '{print $1}'|cut -d '.' -f1`   #RUNLIMIT TIME IN min
   time_limit_parallelq_l=$((time_limit_parallelq_l_min / 60 )) ##RUNLIMIT TIME IN hours
   serialq_push=s_long
   serialq_l=s_long
   time_limit_serialq_l_min=`bqueues -l $serialq_l|grep min|awk '{print $1}'|cut -d '.' -f1`   #RUNLIMIT TIME IN min
   time_limit_serialq_l=$((time_limit_serialq_l_min / 60 )) ##RUNLIMIT TIME IN hours
# DIRECTORIES Juno
#   BACKUPDIR=/marconi_scratch/usera07cmc/a07cmc00/backup
#   pushdirapec=/data/products/C3S/$(whoami)/push_APEC
#   pushdir=$WORK/push/
   if [[ $(whoami) == ${operational_user} ]] 
   then
     	pushdir=/data/products/C3S/$(whoami)/push/
   fi
   SCRATCHDIR1=/work/csp/${operational_user}/scratch
   SCRATCHDIR=$WORK/scratch
   DIR_TEMP=$SCRATCHDIR/CMCC-$CPSSYS/temporary
   DIR_TEMP_NEMOPLOT=$SCRATCHDIR/nemo_timeseries
   DIR_TEMP_CICEPLOT=$SCRATCHDIR/SIE
#   FINALARCHIVE1=/work/csp/${operational_user}/test_archive/CPS/${CPSSYS}/
#   FINALARCHIVE=/work/csp/`whoami`/test_archive/CPS/${CPSSYS}/
#   FINALARCHC3S1=/data/csp/${operational_user}/Seasonal/${CPSSYS}/daily_postpc
#   if [[ `whoami` == ${operational_user} ]] ;then
#      FINALARCHC3S=$FINALARCHC3S1
#   else
#      FINALARCHC3S=$SCRATCHDIR/Seasonal/${CPSSYS}/daily_postpc
#   fi
#   OCNARCHIVE=/data/csp/${operational_user}/ocn${CPSSYS}
   DATA_ARCHIVE=/data/csp/$USER/archive
   DATA_ARCHIVE1=/data/csp/${operational_user}/archive
#   dirdataNOAA=$DATA_ARCHIVE1/noaa_sst/
   DIR_ROOT=$HOME/CPS/CMCC-${CPSSYS}
   DIR_ROOT1=/users_home/csp/${operational_user}/CPS/CMCC-${CPSSYS}
   DIR_CPS=$DIR_ROOT/src/scripts_oper
   DIR_RECOVER=$DIR_ROOT/src/recover
#   OUTDIR_DIAG=/work/csp/sp2/${CPSSYS}/
#   DIR_WEB=/data/products/C3S/sp2/webpage
#   DIR_CLIM=/work/csp/${operational_user}/CESMDATAROOT/C3S_clim_1993_2016/${CPSSYS}
#   DIR_FORE_ANOM=/work/csp/${operational_user}/CMCC-${CPSSYS}/forecast_anom
   DIR_ARCHIVE1=/work/csp/${operational_user}/CMCC-CM/archive
   DIR_ARCHIVE=$WORK_CPS/archive
######## ICs_CLM Juno
   IC_CLM_CPS_DIR1=${DATA_ARCHIVE1}/IC/CLM_${CPSSYS}/
   IC_CLM_CPS_DIR=$SCRATCHDIR/IC/CLM_${CPSSYS}/
   if [ $(whoami) == ${operational_user} ]; then
      IC_CLM_CPS_DIR=$IC_CLM_CPS_DIR1
   fi
#   WOIS=/work/csp/${operational_user}/SPS/CMCC-OIS/
######## ICs_NEMO Juno
# TEMPORARY FOR TESTS
   IC_NEMO_CPS_DIR=$SCRATCHDIR/IC/NEMO_${CPSSYS}/
   IC_NEMO_CPS_DIR1=${DATA_ARCHIVE1}/IC/NEMO_${CPSSYS}/
   if [ $(whoami) == ${operational_user} ]; then
      IC_NEMO_CPS_DIR=$IC_NEMO_CPS_DIR1
   fi
######## ICs_CICE Juno
# TEMPORARY FOR TESTS
   IC_CICE_CPS_DIR=$SCRATCHDIR/IC/CICE_${CPSSYS}/
   IC_CICE_CPS_DIR1=${DATA_ARCHIVE1}/IC/CICE_${CPSSYS}/
   if [ $(whoami) == ${operational_user} ]; then
      IC_CICE_CPS_DIR=$IC_CICE_CPS_DIR1
   fi
######## ICs_CAM Juno
   IC_CAM_CPS_DIR=${SCRATCHDIR}/IC/CAM_${CPSSYS}/
   IC_CAM_CPS_DIR1=${DATA_ARCHIVE1}/IC/CAM_${CPSSYS}/
   if [ $(whoami) == ${operational_user} ]; then
      IC_CAM_CPS_DIR=$IC_CAM_CPS_DIR1
   fi
# TEMPORARY
   if [[ $machine == "juno" ]]
   then
      DATA_ECACCESS=/work/csp/cp1/scratch/DATA_ECACCESS
   elif [[ $machine == "zeus" ]]
   then
      DATA_ECACCESS=/data/delivery/csp/ecaccess/
   fi
   WORK_C3S1=/work/csp/$operational_user/CESM/archive/C3S/
#   WORK_C3Shind=/data/csp/$operational_user/archive/CESM/${CPSSYS}/C3S/
   hsmmail=${mymail}
   ecmwfmail=${mymail}
   ccmail=${mymail}
   if [ $(whoami) == ${operational_user} ]; then
     	ecmwfmail=adrien.owono@ecmwf.int
	     ccmail=silvio.gualdi@cmcc.it,stefanotib@gmail.com
	     hsmmail=hsm@cmcc.it
   fi
#   CLIM_DIR_DIAG=/work/csp/sp2/${CPSSYS}/CESM/monthly/
#   PCTL_DIR_DIAG=/work/csp/sp2/${CPSSYS}/CESM/pctl/
   #directory for CLM restart clim/std dev (for check on ICs)
#   clm_clim_dir=${DIR_CLIM}/CLM_restart

# ######## MARCONI SECTION
elif [[ "$machine" == "marconi" ]]
then
    operational_user=`whoami`
   BATCHRUN="RUN"
   BATCHPEND="PEND"
#    nmax_lt_arch_md=15   #in SPS3.5 15 lt_archive_C3S_moredays occupy ~ 1TB
#    pID=1234
#    apprun=dummy
#    S_apprun=dummy
#    slaID=s_met_cmcc_p
#    sla_serialID=s_met_cmcc_s
#    BATCHRUN="RUNNING"
#    nmb_nemo_domains=336
#    serialq_s=skl_usr_dbg
#    serialq_m=skl_usr_dbg
#    serialq_l=skl_usr_dbg
#    parallelq_s=skl_usr_prod
#    parallelq_m=skl_usr_prod
#    parallelq_l=skl_usr_prod
#    serialq_push=bdw_all_serial
#    serial_test=bdw_all_serial
# #THESE ARE DEFINED TO BE USED ONLY BY submitcommand.sh in  Juno
# #   time_limit_serialq_m_min=`bqueues -l $serialq_m|grep min|awk '{print $1}'|cut -d '.' -f1`   #RUNLIMIT TIME IN min
# #   time_limit_serialq_m=$((time_limit_serialq_m_min / 60 )) ##RUNLIMIT TIME IN hours
# #   time_limit_parallelq_s_min=`bqueues -l $parallelq_s|grep min|awk '{print $1}'|cut -d '.' -f1`   #RUNLIMIT TIME IN min
# #   time_limit_parallelq_s=$((time_limit_parallelq_s_min / 60 )) ##RUNLIMIT TIME IN hours
# #   time_limit_parallelq_m=$((time_limit_parallelq_m_min / 60 )) ##RUNLIMIT TIME IN hours
# #   time_limit_parallelq_l_min=`bqueues -l $parallelq_l|grep min|awk '{print $1}'|cut -d '.' -f1`   #RUNLIMIT TIME IN min
# #   time_limit_parallelq_l=$((time_limit_parallelq_l_min / 60 )) ##RUNLIMIT TIME IN hours
# #   time_limit_serialq_l_min=`bqueues -l $serialq_l|grep min|awk '{print $1}'|cut -d '.' -f1`   #RUNLIMIT TIME IN min
# #   time_limit_serialq_l=$((time_limit_serialq_l_min / 60 )) ##RUNLIMIT TIME IN hours
#    WORK=/marconi_work/CMCC_Copernic/
#    BACKUPDIR=/marconi_scratch/usera07cmc/a07cmc00/backup
#    pushdir=$WORK/push
#    SCRATCHDIR1=$WORK/scratch
#    SCRATCHDIR=$WORK/scratch
    FINALARCHIVE=$WORK/data/archive/CESM/${CPSSYS}/
#    FINALARCHIVE1=$FINALARCHIVE
#    FINALARCHC3S1=$FINALARCHIVE/daily
#    FINALARCHC3S=$FINALARCHC3S1
#    OCNARCHIVE=$WORK/data/ocn${CPSSYS}/
#    DATA_ARCHIVE1=$WORK/data/archive
# #TO BE DEFINED +
#    pushdirapec=$SCRATCHDIR1
#    dirdataNOAA=$SCRATCHDIR1
#    WOIS=$SCRATCHDIR1
#    DATA_ECACCESS=$SCRATCHDIR1
# #TO BE DEFINED -
#    DIR_ROOT=$HOME/SPS/CMCC-${CPSSYS}
#    DIR_ROOT1=$DIR_ROOT
#    OUTDIR_DIAG=$WORK/diagnostics
# # THIS SHOULD NOT BE DEFINED +  here is meant as dummy
#    DIR_WEB=$SCRATCHDIR1
# # THIS SHOULD NOT BE DEFINED -
#    DIR_CLIM=$CESMDATAROOT/C3S_clim_1993_2016/${CPSSYS}
#    DIR_ARCHIVE1=$WORK/CESM/archive
#    DIR_FORE_ANOM=$WORK/CMCC-${CPSSYS}/forecast_anom
# ######## ICs_CLM
#    IC_CLM_CPS_DIR1=$DATA_ARCHIVE1/IC/CLM_${CPSSYS}/
#    IC_CLM_CPS_DIR=$IC_CLM_CPS_DIR1
# ######## ICs_NEMO
#    IC_NEMO_CPS_DIR1=$DATA_ARCHIVE1/IC/NEMO_${CPSSYS}/
#    IC_NEMO_CPS_DIR=$IC_NEMO_CPS_DIR1
# ######## ICs_CAM
#    IC_CAM_CPS_DIR1=$DATA_ARCHIVE1/IC/CAM_${CPSSYS}/
#    IC_CAM_CPS_DIR=$IC_CAM_CPS_DIR1
#    WORK_C3S1=$DIR_ARCHIVE1/C3S
#    if [ $(whoami) == ${operational_user} ]; then
#      	ecmwfmail=$mymail
# 	     ccmail=$mymail
# 	     hsmmail=$mymail
#    fi
#    CLIM_DIR_DIAG=$SCRATCHDIR1/${CPSSYS}/CESM/monthly/
#    PCTL_DIR_DIAG=$SCRATCHDIR1/${CPSSYS}/CESM/pctl//
fi
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# PARAMS to be set
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# extramail=1     # 1 if you want more controls, 0 if you do not 
# forecastday="02" # FORECAST starts the second of the month
# endforecastday="08" # late FORECAST end 
# n_notif=6
FINALARCHIVE=$WORK/data/archive/CESM/${CPSSYS}/
nmonfore=6      # number of forecast months
fixsimdays=185  # total number of simulation days
# maxjobs_APEC=20 # 20 max number of APEC job submitted
# nmaxmem_APEC=20 # 20 max number of realization required to APEC
 natm3d=5    # number of required fields for C3S 3d atmospheric
 nfieldsC3S=55    # number of required fields for C3S with ocean  monthly + new pwr var + two 100m widn components
# nfieldsC3Skeep=19    # C3S fields to keep in archive
# nfieldsC3Socekeep=12 # C3S fields to keep in archive
header="ensemble4"
# jobIDdummy=1234
versionSPS=20231101
GCM_name=CMCC-CM3
endy_hind=2022
iniy_hind=1993
iniy_fore=2024
freq_forcings=8
# 
# #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# # define here operational directories to be used by SPS4
# #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 
# #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# # DIRS to be set
# #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# DIR_CHECK_IC_NEMO=$SCRATCHDIR/check_newICs_nemo/
DIR_CESM=/users_home/$DIVISION/${operational_user}/CMCC-CM/
DIR_SRC=$DIR_ROOT/src
DIR_CHECK=$DIR_ROOT/checklists
# DIR_TEST_SUITE=$DIR_SRC/test_suite
DIR_UTIL=$DIR_SRC/util
dictionary=$DIR_UTIL/CPS1_checkfile_dictionary.txt
DIR_DIAG=$DIR_SRC/diagnostics
DIR_DIAG_C3S=$DIR_DIAG/C3S
DIR_TEMPL=$DIR_SRC/templates
DIR_LOG1=/work/csp/$operational_user/CPS/CMCC-${CPSSYS}/logs
DIR_LOG=/work/csp/$USER/CPS/CMCC-${CPSSYS}/logs
DIR_REST_INI=/work/csp/$operational_user/CPS/CMCC-${CPSSYS}/restart_ini
DIR_PORT=$DIR_SRC/porting
TRIP_DIR=$DIR_ROOT/triplette_done
IC_CPS=$DIR_SRC/IC_CPS/
DIR_ATM_IC=$IC_CPS/IC_CAM
DIR_OCE_IC=$IC_CPS/IC_NEMO
DIR_LND_IC=$IC_CPS/IC_CLM
#REPOSITORY=$MYCESMDATAROOT/CMCC-${CPSSYS}/inputs/files4${CPSSYS}
REPOGRID=$MYCESMDATAROOT/CMCC-${CPSSYS}/regrid_files
DIR_EXE=$DIR_ROOT/executables_cesm
DIR_EXE1=$DIR_ROOT1/executables_cesm
#DIR_REP=$DIR_LOG/reports
DIR_POST=$DIR_SRC/postproc
DIR_C3S=$DIR_POST/C3S_standard
WORK_CPS=$WORK/CMCC-CM
WORK_CPS1=$WORK1/CMCC-CM
DIR_CASES=$WORK/CPS/CMCC-${CPSSYS}/cases
DIR_CASES1=$WORK1/CPS/CMCC-${CPSSYS}/cases
DIR_SUBM_SCRIPTS1=/work/csp/$operational_user/CPS/CMCC-${CPSSYS}/SUBM_SCRIPTS
DIR_SUBM_SCRIPTS=/work/csp/$USER/CPS/CMCC-${CPSSYS}/SUBM_SCRIPTS
# ######## WORK DIRS FOR C3S 
DIR_ARCHIVE_C3S=$DIR_ARCHIVE/C3S
WORK_C3S=$DIR_ARCHIVE_C3S
# ####### WORK DIRS FOR ICs
WORKDIR_LAND=$WORK/WORK_LAND_IC
# ####### REPO for EDA forcing - 3hourly for CLM
forcDIReda=${MYCESMDATAROOT}/CMCC-${CPSSYS}/inputs/FORC4CLM
# ######## ICs_CAM
IC_CPS_guess=$WORK/CPS/CMCC-${CPSSYS}/IC_CPS_guess
WORK_IC4CAM=$WORK/CPS/CMCC-${CPSSYS}/WORK_IC4CAM
# ######## ECOPER_RCP85_CLM45
#forcDIRera5=$MYCESMDATAROOT/inputdata/atm/datm7/${CPSSYStem}_atm_forcing.datm7.ERA5.0.5d
