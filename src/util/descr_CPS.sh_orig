#!/bin/sh -l
set -a
mymail=sp1@cmcc.it
#mymail=antonella.sanna@cmcc.it
#mymail=andrea.borrelli@cmcc.it
flag_dev=0    # if 1 won't use the SC on cmcc
cmd_IC_pull_from_remote="sftp -P 20022  -i $HOME/.ssh/id_ed25519 cineca_cps@dtn01.cmcc.it"
cmd_IC_pull_from_remote_resume="sftp -a -P 20022  -i $HOME/.ssh/id_ed25519 cineca_cps@dtn01.cmcc.it"
if [[ -n `echo $PS1|grep leonardo` ]]
then
   machine="leonardo"
elif [[ -n `echo $PS1|grep juno` ]]
then
   machine="juno"
   alias rm="rm -f"
   alias cp="/bin/cp -f"
   alias mv="mv -f"
elif [[ -n `echo $PS1|grep cassandra` ]]
then
   machine="cassandra"
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
c3s_checker_cmd=c3s-checker
envcondac3schecker=c3schecker
SPSSystem=sps4
DPSSystem=dps3
CPSSYS=CPS1
yyyySCEN=2014
refcaseHIST=${CPSSYS}_HIST_reference
refcaseSCEN=${CPSSYS}_SSP585_reference
envcondanemo=nemo_rebuild
envcondarclone=rclone_gdrive
envcondaclm=postpc_CLM_C3S
DIR_ROOT=$HOME/CPS/CMCC-${CPSSYS}
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Machine dependent vars
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [[ "$machine" == "juno" ]] || [[ "$machine" == "zeus" ]] || [[ "$machine" == "cassandra" ]]
then
   qos=qos_lowprio   #this is used only for SLURM but it is
                     #necessary for portability being used in
                     #submitcommand
#   nmax_lt_arch_md=15   #in SPS3.5 15 lt_archive_C3S_moredays occupy ~ 1TB
#   envcondarclone=rclone_gdrive
   if [[ $machine == "juno" ]] 
   then
      HEAD=cmcc
      operational_user=cp1
      pID=0490 #Juno
#      pID=0438 #Juno
      cores_per_node=72
      nnodes_SC=56
      cores_per_run=288
      mpilib4py_nemo_rebuild=impi-2021.6.0/2021.6.0
      mpirun4py_nemo_rebuild=mpiexec.hydra
      envcondacm3=cmcc-cm_py39
      maxnumbertosubmit=18
      maxnumbertorecover=40
      maxnumberguarantee=7
      env_workflow_tag=cmcc
      DIR_REST_OIS_FORE=$WORK/OIS2/archive/  #TO BE DEFINED ONCE SET
      DIR_REST_OIS=/work/$HEAD/aspect/CESM2/rea_archive/
      DATA_ECACCESS=/data/delivery/csp/cp1/in/
   elif [[ $machine == "cassandra" ]]
   then
      refcaseHIST=${CPSSYS}_HIST_reference_esmf8.4
      refcaseSCEN=${CPSSYS}_SSP585_reference_esmf8.4
      HEAD=cmcc
      operational_user=cp1
      pID=0490 #Juno
#      pID=0438 #Juno
      cores_per_node=112
      nnodes_SC=56
      cores_per_run=336
      mpilib4py_nemo_rebuild=impi-2021.6.0/2021.6.0
      mpirun4py_nemo_rebuild=mpiexec.hydra
      envcondacm3=cmcc-cm_sps4
      envcondarclone=/users_home/cmcc/cp2/miniconda/envs/rclone_CPS1
      maxnumbertosubmit=5
      maxnumbertorecover=40
      maxnumberguarantee=7
      env_workflow_tag=cmcc
      DIR_REST_OIS_FORE=$WORK/OIS2/archive/  #TO BE DEFINED ONCE SET
      DIR_REST_OIS=/work/$HEAD/aspect/CESM2/rea_archive/
      DATA_ECACCESS=/data/delivery/csp/cp1/in/
   elif [[ $machine == "zeus" ]]
   then
      HEAD=csp
      pID=0574 #zeus
#      pID=0438 #zeus
      nnodes_SC=120
      cores_per_node=36
      cores_per_run=720
      operational_user=sps-dev
      maxnumbertorecover=40
      maxnumbertosubmit=10
      maxnumberguarantee=6
      mpilib4py_nemo_rebuild=impi20.1/19.7.217
      mpirun4py_nemo_rebuild=mpirun
      envcondaclm=/work/$HEAD/sp1/anaconda3/envs/CMOR_5
      envcondacm3=/users_home/$HEAD/dp16116/.conda/envs/py38CS2
      env_workflow_tag=cmcc
      DATA_ECACCESS=/data/delivery/$HEAD/ecaccess/
   fi
   MYCESMDATAROOT1=/data/$HEAD/$operational_user/
   MYCESMDATAROOT=/data/$HEAD/$operational_user/
   DATA_ARCHIVE=/data/$HEAD/$USER/archive
   DATA_ARCHIVE1=/data/$HEAD/${operational_user}/archive
   DIR_ROOT1=/users_home/$HEAD/${operational_user}/CPS/CMCC-${CPSSYS}
   WORK=/work/$HEAD/$USER/
   WORK1=/work/$HEAD/$operational_user/
   DIR_CESM=/users_home/$HEAD/${operational_user}/CMCC-CM/
   S_apprun=SERIAL_sps35 #Zeus
   apprun=sps35 #Zeus
#now suppressed because redundant
   sla_serialID=SC_SERIAL_sps35 #Zeus
   slaID=SC_sps35 #Zeus
   BATCHUNKNOWN="UNKN"
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
   serialq_push=s_download
   time_limit_serialq_l_min=`bqueues -l $serialq_l|grep min|awk '{print $1}'|cut -d '.' -f1`   #RUNLIMIT TIME IN min
   time_limit_serialq_l=$((time_limit_serialq_l_min / 60 )) ##RUNLIMIT TIME IN hours
# DIRECTORIES Juno
#   BACKUPDIR=/marconi_scratch/usera07cmc/a07cmc00/backup
#   pushdirapec=/data/products/C3S/$(whoami)/push_APEC
#   if [[ $(whoami) == ${operational_user} ]] 
#   then
#     	pushdir=/data/products/C3S/$(whoami)/push/
#   fi
   DIR_TEMP=$SCRATCHDIR/CMCC-$CPSSYS/temporary
   DIR_TEMP_NEMOPLOT=$SCRATCHDIR/nemo_timeseries
   DIR_TEMP_CICEPLOT=$SCRATCHDIR/SIE
#   FINALARCHIVE1=/work/csp/${operational_user}/test_archive/CPS/${CPSSYS}/
#   FINALARCHIVE=/work/csp/`whoami`/test_archive/CPS/${CPSSYS}/
   FINALARCHC3S1=/data/products/CMCC_SPS4/C3S_daily
   if [[ `whoami` == ${operational_user} ]] ;then
      FINALARCHC3S=$FINALARCHC3S1
   else
      FINALARCHC3S=$SCRATCHDIR/CMCC_SPS4/C3S_daily
   fi
#   OCNARCHIVE=/data/csp/${operational_user}/ocn${CPSSYS}
   dirdatacheckIC=$DATA_ARCHIVE1/check_ICs/
   dirdataESA=${dirdatacheckIC}/ESA_sst 
   OUTDIR_DIAG=$WORK/diagnostics/
   #DIR_WEB=$WORK/CPS/C3Swebpage/validation_dev
   DIR_WEB=$WORK/CPS/C3Swebpage
#   DIR_CLIM=/work/csp/${operational_user}/CESMDATAROOT/C3S_clim_1993_2016/${CPSSYS}
   WORK_CPS=${WORK}/CMCC-CM/
   WORK_CPS1=${WORK1}/CMCC-CM/
   DIR_ARCHIVE=$WORK_CPS/archive
   DIR_ARCHIVE1=${WORK_CPS1}/archive
   SCRATCHDIR1=${WORK1}/scratch
   SCRATCHDIR=$WORK/scratch
######## ICs_CLM Juno
   IC_CLM_CPS_DIR1=${DATA_ARCHIVE1}/IC/CLM_${CPSSYS}/
   IC_CLM_CPS_DIR=$SCRATCHDIR/IC/CLM_${CPSSYS}/
   if [[ $(whoami) == ${operational_user} ]]; then
      IC_CLM_CPS_DIR=$IC_CLM_CPS_DIR1
   fi
   WOIS=/work/cmcc/${operational_user}/CPS/CMCC-OIS2/
######## ICs_NEMO Juno
# TEMPORARY FOR TESTS
   IC_NEMO_CPS_DIR=$SCRATCHDIR/IC/NEMO_${CPSSYS}/
   IC_NEMO_CPS_DIR1=${DATA_ARCHIVE1}/IC/NEMO_${CPSSYS}/
   if [[ $(whoami) == ${operational_user} ]]; then
      IC_NEMO_CPS_DIR=$IC_NEMO_CPS_DIR1
   fi
######## ICs_CICE Juno
# TEMPORARY FOR TESTS
   IC_CICE_CPS_DIR=$SCRATCHDIR/IC/CICE_${CPSSYS}/
   IC_CICE_CPS_DIR1=${DATA_ARCHIVE1}/IC/CICE_${CPSSYS}/
   if [[ $(whoami) == ${operational_user} ]]; then
      IC_CICE_CPS_DIR=$IC_CICE_CPS_DIR1
   fi
######## ICs_CAM Juno
   IC_CAM_CPS_DIR=${SCRATCHDIR}/IC/CAM_${CPSSYS}/
   IC_CAM_CPS_DIR1=${DATA_ARCHIVE1}/IC/CAM_${CPSSYS}/
   if [[ $(whoami) == ${operational_user} ]]; then
      IC_CAM_CPS_DIR=$IC_CAM_CPS_DIR1
   fi
#   WORK_C3Shind=/data/csp/$operational_user/archive/CESM/${CPSSYS}/C3S/
   hsmmail=${mymail}
   ecmwfmail=${mymail}
   ccmail=${mymail}
   if [[ $(whoami) == ${operational_user} ]]; then
     	ecmwfmail=adrien.owono@ecmwf.int
      ccmail=leone.cavicchia@cmcc.it,stefanotib@gmail.com
	     hsmmail=hsm@cmcc.it
   fi
   VALIDATION=$WORK/CPS/VALIDATION
   EVALUATION=$WORK/CPS/EVALUATION
   CLIM_OBS_DIR_DIAG=$VALIDATION/OBS/
   PCTL_OBS_DIR_DIAG=$CLIM_OBS_DIR_DIAG/pctl
   CLIM_DIR_DIAG=${WORK_SCORES}/monthly
   PCTL_DIR_DIAG=${WORK_SCORES}/pctl
   #directory for CLM restart clim/std dev (for check on ICs)
#   clm_clim_dir=${DIR_CLIM}/CLM_restart

# ######## MARCONI SECTION
elif [[ "$machine" == "leonardo" ]]
then 
   env_workflow_tag=leonardo
   envcondacm3=cmcc-cm_py
   envcondac3schecker=c3s-nc-checker
   mpirun4py_nemo_rebuild=srun
   mpilib4py_nemo_rebuild=intel-oneapi-mpi/2021.10.0
#moved to .bashrc
   if [[ $account_SLURM == "CMCC_reforeca" ]]
   then
      qos=qos_lowprio
   else
#   account_name=CMCC_Copernic_4
      qos=qos_cmcc
   fi
# only for July we must set it to ""
   if [[ $qos == "qos_lowprio" ]]
   then
     #for running with CMCC_reforeca
      optSLURM="--qos=$qos"
      serialq_s=dcgp_usr_prod
     serialq_m=dcgp_usr_prod
     serialq_l=dcgp_usr_prod
     parallelq_s=dcgp_usr_prod
     parallelq_m=dcgp_usr_prod
     parallelq_l=dcgp_usr_prod
   else   
      #for running with account CMCC_2025
      #optSLURM="--reservation=s_met_cmcc"
      optSLURM="--qos=$qos"
      serialq_s=dcgp_cmcc_prod
      serialq_m=dcgp_cmcc_prod
      serialq_l=dcgp_cmcc_prod
      parallelq_s=dcgp_cmcc_prod
      parallelq_m=dcgp_cmcc_prod
      parallelq_l=dcgp_cmcc_prod

   fi     
   #maxnumbertosubmit=62 #modifyied 20240729
   maxnumbertosubmit=54 #20250801 new partition with 3 nodes free for postproc
   maxnumbertorecover=$maxnumbertosubmit
   operational_user=`whoami`
   MYCESMDATAROOT=$CESMDATAROOT
   MYCESMDATAROOT1=$CESMDATAROOT
   DIR_CESM=$HOME/CMCC-CM/
   BATCHRUN="RUN"
   BATCHPEND="PEND"
#    nmax_lt_arch_md=15   #in SPS3.5 15 lt_archive_C3S_moredays occupy ~ 1TB
   pID=1234
   apprun=dummy
   S_apprun=dummy
   slaID=s_met_cmcc_p
   sla_serialID=s_met_cmcc_s
   nmb_nemo_domains=336
   serialq_push=lrd_all_serial
   serial_test=lrd_all_serial
   WORK=/leonardo_work/$account_name/  #is environment var in leonardo
   WORK1=$WORK
   WORK_CPS=${WORK}/CMCC-CM/
   WORK_CPS1=${WORK_CPS1}
   DIR_ARCHIVE=${WORK_CPS}/archive
   DIR_ARCHIVE1=$DIR_ARCHIVE
#    BACKUPDIR=/marconi_scratch/usera07cmc/a07cmc00/backup to be defined
#    pushdir=$WORK/push to be defined
    #SCRATCHDIR=$WORK/scratch
#    SCRATCHDIR=/leonardo_work/CMCC_reforeca/scratch 20250915
    SCRATCHDIR=/leonardo_work/CMCC_2025/scratch
    SCRATCHDIR1=$SCRATCHDIR
    FINALARCHC3S=$WORK/CMCC_SPS4/C3S_daily
    FINALARCHC3S1=$FINALARCHC3S
    DIR_TEMP=$SCRATCHDIR/CMCC-$CPSSYS/temporary
# #TO BE DEFINED +
#    pushdirapec=$SCRATCHDIR1
#    dirdataNOAA=$SCRATCHDIR1
#    WOIS=$SCRATCHDIR1
#    DATA_ECACCESS=$SCRATCHDIR1
#    DIR_CLIM=$CESMDATAROOT/C3S_clim_1993_2016/${CPSSYS}
# #TO BE DEFINED -
    DIR_ROOT1=$DIR_ROOT
    OUTDIR_DIAG=$WORK/diagnostics
    DIR_FORE_ANOM=$WORK/CMCC-${CPSSYS}/forecast_anom
# ######## ICs_CLM
    IC_CLM_CPS_DIR1=$SCRATCHDIR1/IC/CLM_${CPSSYS}/
    IC_CLM_CPS_DIR=$IC_CLM_CPS_DIR1
# ######## ICs_NEMO
    IC_NEMO_CPS_DIR1=$SCRATCHDIR1/IC/NEMO_${CPSSYS}/
    IC_NEMO_CPS_DIR=$IC_NEMO_CPS_DIR1
# ######## ICs_CICe
    IC_CICE_CPS_DIR1=$SCRATCHDIR1/IC/CICE_${CPSSYS}/
    IC_CICE_CPS_DIR=$IC_CICE_CPS_DIR1
# ######## ICs_CAM
    IC_CAM_CPS_DIR1=$SCRATCHDIR1/IC/CAM_${CPSSYS}/
    IC_CAM_CPS_DIR=$IC_CAM_CPS_DIR1
   	ecmwfmail=$mymail
    ccmail=$mymail
    hsmmail=$mymail
    CLIM_DIR_DIAG=$WORK_SCORES/monthly/
    PCTL_DIR_DIAG=$WORK_SCORES/pctl//
fi
WORK_C3S1=$DIR_ARCHIVE1/C3S
WORK_C3S=$WORK_C3S1
DIR_LOG1=$WORK1/CPS/CMCC-${CPSSYS}/logs
DIR_LOG=$WORK/CPS/CMCC-${CPSSYS}/logs
HEALED_DIR_ROOT=$WORK1/CPS/CMCC-${CPSSYS}/fixed_from_spikes
DIR_SUBM_SCRIPTS1=$WORK1/CPS/CMCC-${CPSSYS}/SUBM_SCRIPTS
DIR_SUBM_SCRIPTS=$WORK/CPS/CMCC-${CPSSYS}/SUBM_SCRIPTS
DIR_REST_INI=$WORK/CPS/CMCC-${CPSSYS}/restart_ini
DIR_NEMO_REBUILD=$DIR_CESM/components/nemo/source/utils/py_nemo_rebuild/src/py_nemo_rebuild/
DIR_CPS=$DIR_ROOT/src/scripts_oper
DIR_RECOVER=$DIR_ROOT/src/recover
pushdir=$WORK/CPS/CMCC-${CPSSYS}/push
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
 nfieldsC3S=56    # number of required fields for C3S with ocean  monthly + new pwr var + two 100m widn components
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
REPOSITORY=$MYCESMDATAROOT/CMCC-${CPSSYS}/files4${CPSSYS}
REPOSITORY1=$MYCESMDATAROOT1/CMCC-${CPSSYS}/files4${CPSSYS}
REPOGRID=$MYCESMDATAROOT/CMCC-${CPSSYS}/regrid_files
REPOGRID1=$MYCESMDATAROOT1/CMCC-${CPSSYS}/regrid_files
DIR_SRC=$DIR_ROOT/src
DIR_CHECK=$DIR_ROOT/checklists
# DIR_TEST_SUITE=$DIR_SRC/test_suite
DIR_UTIL=$DIR_SRC/util
dictionary=$DIR_UTIL/${CPSSYS}_checkfile_dictionary.txt
DIR_DIAG=$DIR_SRC/diagnostics
DIR_DIAG_C3S=$DIR_DIAG/C3S
DIR_TEMPL=$DIR_SRC/templates
DIR_PORT=$DIR_SRC/porting
TRIP_DIR=$DIR_ROOT/triplette_done
IC_CPS=$DIR_SRC/IC_CPS/
DIR_ATM_IC=$IC_CPS/IC_CAM
DIR_OCE_IC=$IC_CPS/IC_NEMO
DIR_LND_IC=$IC_CPS/IC_CLM
DIR_EXE=$DIR_ROOT/executables_cesm
DIR_EXE1=$DIR_ROOT1/executables_cesm
DIR_REP=$DIR_LOG/REPORTS
DIR_POST=$DIR_SRC/postproc
DIR_C3S=$DIR_POST/C3S_standard
WORK_CPS=$WORK/CMCC-CM
WORK_CPS1=$WORK1/CMCC-CM
DIR_CASES=$WORK/CPS/CMCC-${CPSSYS}/cases
DIR_CASES1=$WORK1/CPS/CMCC-${CPSSYS}/cases
ROOT_CASES_WORK=$WORK1/CPS/CMCC-${CPSSYS}
# ######## WORK DIRS FOR C3S 
DIR_ARCHIVE_C3S=$DIR_ARCHIVE/C3S
WORK_C3S=$DIR_ARCHIVE_C3S
# ####### WORK DIRS FOR ICs
WORKDIR_LAND=$DIR_TEMP/WORK_LAND_IC
WORKDIR_OCE=$DIR_TEMP/WORK_OCE_IC
# ####### REPO for EDA forcing - 3hourly for CLM
forcDIReda=${MYCESMDATAROOT}/CMCC-${CPSSYS}/inputs/FORC4CLM
# ######## ICs_CAM
IC_CPS_guess=$WORK/CPS/CMCC-${CPSSYS}/IC_CPS_guess
WORK_IC4CAM=$WORK/CPS/CMCC-${CPSSYS}/WORK_IC4CAM
# ######## ECOPER_RCP85_CLM45
#forcDIRera5=$MYCESMDATAROOT/inputdata/atm/datm7/${CPSSYStem}_atm_forcing.datm7.ERA5.0.5d
DIR_ROOT_SCORES=$HOME/CPS/CMCC-SPS_SKILL_SCORES
DIR_PCTL=$HOME/CPS/CMCC-SPS_PCTL
WORK_SCORES=$WORK/CPS/CMCC-SPS_SKILL_SCORES/CMCC-SPS4
DIR_CLIM=$WORK_SCORES
DIR_FORE_ANOM=$WORK/CPS/CMCC-${CPSSYS}/forecast_anom
#
if [[ $machine == "juno" ]]
then
   . ~/load_conda;conda activate $envcondacm3
fi
if [[ $flag_dev -eq 1 ]]
then
   sla_serialID="dummy"
   slaID="dummy"
fi

set +a
