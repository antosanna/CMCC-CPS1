#!/bin/sh -l
set -a
#mymail=sp1@cmcc.it
mymail=antonella.sanna@cmcc.it
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
elif [[ -n `echo $PS1|grep zeus` ]]
then
   machine="zeus"
else
   echo "MACHINE UNKNOWN!! EXITING NOW!!"
   exit -1
fi
SPSSystem=sps4
DPSsystem=dps3
CPSSYS=CPS1
yyyySCEN=2015
refcaseHIST=SPS4_HIST_hyb_refcase
#refcaseHIST=SPS4_HIST_hyb_CERISE
refcaseSCEN=SPS4_SCEN_hyb_refcase
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Machine dependent vars
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [[ "$machine" == "juno" ]] || [[ "$machine" == "zeus" ]]
then
   MYCESMDATAROOT=/data/$DIVISION/$USER/
   nmax_lt_arch_md=15   #in SPS3.5 15 lt_archive_C3S_moredays occupy ~ 1TB
   if [[ $machine == "juno" ]]
   then
      operational_user=cp1
      pID=0490 #Juno
      envcondacm3=da_definire
      envcondanemo=de_definire
      maxnumbertosubmit=20
      env_workflow_tag=cmcc
   elif [[ $machine == "zeus" ]]
   then
      pID=0574 #zeus
      operational_user=sara_sps-dev
      maxnumbertosubmit=10
      envcondacm3=/users_home/csp/dp16116/.conda/envs/py38CS2
      envcondanemo=/users_home/csp/as34319/.conda/envs/nemo_rebuild
      env_workflow_tag=cmcc
   fi
   WORK=/work/$DIVISION/$USER/
   WORK1=/work/$DIVISION/$operational_user/
#   apprun=??? #sps35 Zeus
#   S_apprun=??? #SERIAL_sps35 Zeus
#now suppressed because redundant
#   slaID=SC_sps35 #Zeus
#   sla_serialID=SC_SERIAL_sps35 #Zeus
   BATCHRUN="RUN"
   nmb_nemo_domains=279
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
   WORK=/work/$DIVISION/$USER
   WORK1=/work/$DIVISION/$operational_user
   if [[ $machine == "zeus" ]]
   then
      WORK1=$WORK
   fi
#   BACKUPDIR=/marconi_scratch/usera07cmc/a07cmc00/backup
#   pushdirapec=/data/products/C3S/$(whoami)/push_APEC
#   pushdir=$WORK/push/
   if [[ $(whoami) == ${operational_user} ]] || [[ $(whoami) == ${dev_user} ]]
   then
     	pushdir=/data/products/C3S/$(whoami)/push/
   fi
   SCRATCHDIR1=/work/csp/${operational_user}/scratch
   SCRATCHDIR=$WORK/scratch
   FINALARCHIVE1=/work/csp/${operational_user}/test_archive/CPS/${CPSSYS}/
   FINALARCHIVE=/work/csp/`whoami`/test_archive/CPS/${CPSSYS}/
#   FINALARCHIVE1=/data/csp/${operational_user}/archive/CPS/${CPSSYS}/
#   FINALARCHIVE=/data/csp/`whoami`/archive/CPS/${CPSSYS}/
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
#   OUTDIR_DIAG=/work/csp/sp2/${CPSSYS}/
#   DIR_WEB=/data/products/C3S/sp2/webpage
#   DIR_CLIM=/work/csp/${operational_user}/CESMDATAROOT/C3S_clim_1993_2016/${CPSSYS}
#   DIR_FORE_ANOM=/work/csp/${operational_user}/CMCC-${CPSSYS}/forecast_anom
#   DIR_ARCHIVE1=/work/csp/${operational_user}/CESM/archive
######## ICs_CLM Juno
# TEMPORARY FOR TESTS
#   IC_CLM_CPS_DIR=$SCRATCHDIR/IC/CLM_${CPSSYS}/
#   IC_CLM_CPS_DIR1=${DATA_ARCHIVE1}/IC/CLM_${CPSSYS}/
#   if [ $(whoami) == ${operational_user} ]; then
#      IC_CLM_CPS_DIR=$IC_CLM_CPS_DIR1
#   fi
   IC_CLM_CPS_DIR=${DATA_ARCHIVE}/IC/CLM_${CPSSYS}/
   IC_CLM_CPS_DIR1=${DATA_ARCHIVE1}/IC/CLM_${CPSSYS}/
#   WOIS=/work/csp/${operational_user}/SPS/CMCC-OIS/
######## ICs_NEMO Juno
# TEMPORARY FOR TESTS
#   IC_NEMO_CPS_DIR=$SCRATCHDIR/IC/NEMO_${CPSSYS}/
#   IC_NEMO_CPS_DIR1=${DATA_ARCHIVE1}/IC/NEMO_${CPSSYS}/
#   if [ $(whoami) == ${operational_user} ]; then
#      IC_NEMO_CPS_DIR=$IC_NEMO_CPS_DIR1
#   fi
   IC_NEMO_CPS_DIR=$SCRATCHDIR/IC/NEMO_${CPSSYS}_test
   IC_NEMO_CPS_DIR1=$SCRATCHDIR/IC/NEMO_${CPSSYS}_test
######## ICs_NEMO Juno
# TEMPORARY FOR TESTS
#   IC_CICE_CPS_DIR=$SCRATCHDIR/IC/CICE_${CPSSYS}/
#   IC_CICE_CPS_DIR1=${DATA_ARCHIVE1}/IC/CICE_${CPSSYS}/
   IC_CICE_CPS_DIR=$SCRATCHDIR/IC/CICE_${CPSSYS}_test/
   IC_CICE_CPS_DIR1=$SCRATCHDIR/IC/CICE_${CPSSYS}_test/
   if [ $(whoami) == ${operational_user} ]; then
      IC_CICE_CPS_DIR=$IC_CICE_CPS_DIR1
   fi
######## ICs_CAM Juno
# TEMPORARY FOR TESTS
#   IC_CAM_CPS_DIR1=${DATA_ARCHIVE1}/IC/CAM_${CPSSYS}/
#   IIC_CAM_CPS_DIR1C_CAM_CPS_DIR=${SCRATCHDIR}/IC/CAM_${CPSSYS}/
   IC_CAM_CPS_DIR1=${SCRATCHDIR}/IC/CAM_${CPSSYS}_test/
   IC_CAM_CPS_DIR=${SCRATCHDIR}/IC/CAM_${CPSSYS}_test/
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
#   WORK_C3S1=/work/csp/$operational_user/CESM/archive/C3S/
#   WORK_C3Shind=/data/csp/$operational_user/archive/CESM/${CPSSYS}/C3S/
   hsmmail=${mymail}
   ecmwfmail=${mymail}
   ccmail=${mymail}
   CESMENV=/users_home/csp/dp16116/.conda/envs/py38CS2
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
#    dev_user=$operational_user
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
#    FINALARCHIVE=$WORK/data/archive/CESM/${CPSSYS}/
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
nmonfore=6      # number of forecast months
fixsimdays=185  # total number of simulation days
# maxjobs_APEC=20 # 20 max number of APEC job submitted
# nmaxmem_APEC=20 # 20 max number of realization required to APEC
# natm3d=5    # number of required fields for C3S 3d atmospheric
# nfieldsC3S=53    # number of required fields for C3S with ocean  monthly + new pwr var
# nfieldsC3Skeep=19    # C3S fields to keep in archive
# nfieldsC3Socekeep=12 # C3S fields to keep in archive
header="ensemble4"
# jobIDdummy=1234
versionSPS=20231001
endy_hind=2022
iniy_hind=1993
# iniy_fore=2017
# n_ic_cam=10
# n_ic_clm=3
# n_ic_nemo=9
# nproc_postrun=4
freq_forcings=8
# 
# #------------------
# #current refcaseSCEN (13-12-2022 - Mari) needed for introducing new vert interpolation of DMO
# #------------------
# refcaseSPS=${CPSSYS}_XXTR_nospikes
# execesmSPS=cesm.exe.${CPSSYS}_XXTR_nospikes
# exeocnSPS=ocn_nospikes
# refcaseSCEN=${CPSSYS}_RCP8.5_nospikes_newinterp
# execesmSCEN=cesm.exe.${CPSSYS}_RCP8.5_nospikes_newinterp
# exeocnSCEN=ocnRCP8.5_nospikes_newinterp
# 
# #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# # define here operational directories to be used by SPS3
# #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 
# #- - EMAIL to be set
# SPSmail=antonella.sanna@cmcc.it,andrea.borrelli@cmcc.it,marianna.benassi@cmcc.it,zhiqi.yang@cmcc.it
# ARCHIVE=$WORK/archive_${CPSSYS}
# ARCHIVE_IC_CAM=$WORK/IC_CAM_SPS
# ARCHIVE_IC_CLM=$WORK/IC_CLM_SPS
# ARCHIVE_IC_CICE=$WORK/IC_NEMO_SPS
# ARCHIVE_IC_NEMO=$ARCHIVE_IC_CICE
# #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# # DIRS to be set
# #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# DIR_CHECK_IC_NEMO=$SCRATCHDIR/check_newICs_nemo/
#DIR_CESM=/users_home/$DIVISION/$operational_user/CESM2/CMCC-CM_anto/
if [[ $machine == "juno" ]]
then
   DIR_CESM=/users_home/$DIVISION/dp16116/CMCC-CM_dev/
elif [[ $machine == "zeus" ]]
then
   DIR_CESM=/users_home/$DIVISION/as34319/CMCC_CM-dev122/
fi
# DIR_STAT=$DIR_ROOT/static
DIR_SRC=$DIR_ROOT/src
DIR_CHECK=$DIR_ROOT/checklist_run
# DIR_SRC1=$DIR_ROOT1/src
# DIR_TEST_SUITE=$DIR_SRC/test_suite
DIR_UTIL=$DIR_SRC/util
# DIR_DIAG=$DIR_UTIL/diag
# DIR_DIAG_C3S=$DIR_UTIL/diag_C3S_final
DIR_TEMPL=$DIR_SRC/templates
DIR_LOG1=/work/csp/$operational_user/CPS/CMCC-${CPSSYS}/logs
DIR_LOG=/work/csp/$USER/CPS/CMCC-${CPSSYS}/logs
# DIR_PORT=$DIR_SRC/porting
TRIP_DIR=$DIR_ROOT/triplette_done
IC_CPS=$DIR_SRC/IC_CPS/
DIR_ATM_IC=$IC_CPS/IC_CAM
DIR_OCE_IC=$IC_CPS/IC_NEMO
DIR_LND_IC=$IC_CPS/IC_CLM
# REPOSITORY3=$CESMDATAROOT/CMCC-SPS3/files4SPS3
REPOSITORY=$MYCESMDATAROOT/CMCC-${CPSSYS}/inputs/files4${CPSSYS}
REPOGRID=$MYCESMDATAROOT/CMCC-${CPSSYS}/regrid_files
# DIR_REFCASE_RCP=$DIR_ROOT/cases/${refcaseSCEN}
# DIR_REFCASE_XXTR=$DIR_ROOT/cases/${refcaseSPS}
DIR_EXE=$DIR_ROOT/executables_cesm
DIR_EXE1=$DIR_ROOT1/executables_cesm
# DIR_CHECK=$DIR_ROOT/checklist_run
DIR_REP=$DIR_LOG/reports
DIR_POST=$DIR_SRC/postproc
# DIR_C3S=$DIR_POST/C3S_standard
WORK_CPS=$WORK/CMCC-CM
WORK_CPS1=$WORK1/CMCC-CM
DIR_CASES=$WORK/CPS/CMCC-${CPSSYS}/cases
DIR_CASES1=$WORK1/CPS/CMCC-${CPSSYS}/cases
DIR_SUBM_SCRIPTS1=/work/csp/$operational_user/CPS/CMCC-${CPSSYS}/SUBM_SCRIPTS
DIR_SUBM_SCRIPTS=$WORK/CMCC-${CPSSYS}/SUBM_SCRIPTS
DIR_ARCHIVE=$WORK_CPS/archive
# ######## WORK DIRS FOR C3S 
DIR_ARCHIVE_C3S=$DIR_ARCHIVE/C3S
# WORK_C3S=$DIR_ARCHIVE_C3S
# ####### WORK DIRS FOR ICs
# ATM_IC=$WORK_CPS/CMCC-${CPSSYS}/WORK_ATM_IC
WORKDIR_LAND=$WORK/WORK_LAND_IC
# WORKDIR_OCE=$WORK_CPS/CMCC-${CPSSYS}/WORK_OCE_IC
# WORKDIR_ATM=${ATM_IC}
# export dirdata00=$WORK/WORK_ATM_IC/OPER/OPER_00
# export dirdata12=$WORK/WORK_ATM_IC/OPER/OPER_12
# export diracc=$WORKDIR_LAND/WORK_ACC_ECMWF
# export dirinst=$WORKDIR_LAND/WORK_INST_ECMWF
# export dirncep_inst=$WORKDIR_LAND/WORK_INST_NCEP
# export dirncep_acc=$WORKDIR_LAND/WORK_ACC_NCEP
# ######## ICs_Nemo
# TEMPORARY
DIR_REST_OIS=/work/csp/aspect/CESM2/rea_archive/
# NEMO_DIR=$WOIS/run/oper_weekly
# wrk_IC_NEMO=$WORKDIR_OCE
# ######## ICs_Nemo_Cice_backup
# OISBKDIR=$WOIS/run/oper_weekly
# export OISDIR=$WOIS/C-GLORSv6
# OIS=~${operational_user}/SPS/CMCC-OIS
# IC_4NEMO_SPINUP_DIR=$WORK/IC_4NEMO_SPINUP/
# ######## ICs_CAM
# IC_atm_guess=$WORK/CMCC-${CPSSYS}/IC_atm_guess
IC_CPS_guess=$WORK/CPS/CMCC-${CPSSYS}/IC_CPS_guess
WORK_IC4CAM=$WORK/CPS/CMCC-${CPSSYS}/WORK_IC4CAM
# export ATMDIROUT_00=$IC_CAM_CPS_DIR/work00
# export ATMDIROUT_12=$IC_CAM_CPS_DIR/work12
# # FORCINGS CLM
# #NCOPER_RCP85_CLM45
# forcDIRncep=$CESMDATAROOT/inputdata/atm/datm7/${CPSSYStem}_atm_forcing.datm7.NCOPER.0.5d 
# ######## ECOPER_RCP85_CLM45
# forcDIRecmwf=$CESMDATAROOT/inputdata/atm/datm7/${CPSSYStem}_atm_forcing.datm7.ECOPER.0.5d 
# ######## LOPER_RCP85_CLM45
# forcDIRlin1=$CESMDATAROOT/inputdata/atm/datm7/${CPSSYStem}_atm_forcing.datm7.LOPER.0.5d  
# ######## NCOPER2CAM_RCP85_CLM45
# forcDIRncep2cam=$CESMDATAROOT/inputdata/atm/datm7/${CPSSYStem}_atm_forcing.datm7.NCOPER2CAM.0.5d 
# ######## ECOPER2CAM_RCP85_CLM45
# forcDIRecmwf2cam=$CESMDATAROOT/inputdata/atm/datm7/${CPSSYStem}_atm_forcing.datm7.ECOPER2CAM.0.5d 
# #### LOPER2CAM_RCP85_CLM45
# forcDIRlin12cam=$CESMDATAROOT/inputdata/atm/datm7/${CPSSYStem}_atm_forcing.datm7.LOPER2CAM.0.5d 
# ####### NEW ERA5 forcing
forcDIRera5=$MYCESMDATAROOT/inputdata/atm/datm7/${CPSSYStem}_atm_forcing.datm7.ERA5.0.5d
# ####### NEW ERA5 forcing (Backup)
# forcDIRera52cam=$CESMDATAROOT/inputdata/atm/datm7/${CPSSYStem}_atm_forcing.datm7.ERA52CAM.0.5d
# ####### NEW GFS forcing
# forcDIRgfs=$CESMDATAROOT/inputdata/atm/datm7/${CPSSYStem}_atm_forcing.datm7.GFS.0.5d
# ####### NEW GFS forcing (Backup)
# forcDIRgfs2cam=$CESMDATAROOT/inputdata/atm/datm7/${CPSSYStem}_atm_forcing.datm7.GFS2CAM.0.5d
# ####### NEW LIN forcing (GFS+ERA5)
# forcDIRnewlin=$CESMDATAROOT/inputdata/atm/datm7/${CPSSYStem}_atm_forcing.datm7.newLIN.0.5d
# ####### NEW LIN forcing (GFS+ERA5 -Backup)
# forcDIRnewlin2cam=$CESMDATAROOT/inputdata/atm/datm7/${CPSSYStem}_atm_forcing.datm7.newLIN2CAM.0.5d
# 
# ####### EXECUTABLE OCN
# SCRIPT_REB=$DIR_EXE/ocn2013/REBUILD_NEMO/rebuild_nemo
# ######## SPINUP LAND REFCASES DIR
# spinup_refcase_ecmwf=$DIR_ARCHIVE/land_clm45_forced_ECOPER_RCP85
# spinup_refcase_ncep=$DIR_ARCHIVE/land_clm45_forced_NCOPER_RCP85
# spinup_refcase_lin1=$DIR_ARCHIVE/land_clm45_forced_LOPER_RCP85
# set +a
