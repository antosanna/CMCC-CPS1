#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# PARAMS to be set
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
yyyy=$1
nmaxjob=32      # 32 max number of job submitted on poe
nminjob=17      # 17 max number of job submitted on poe
extramail=1     # 1 if you want more controls, 0 if you do not 
nrunmax=55      # 55 number of realizations you want to produce
nmonfore=7
nrunC3Sfore=50  # 50 number of realizations required to C3S forecast
maxjobs_APEC=10 # 20 max number of APEC job submitted
if [[ $yyyy -lt 2023 ]]
then
   nmaxmem_APEC=30 
else
   nmaxmem_APEC=${nrunC3Sfore}
fi
version=20231101
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# define here operational directories to be used by SPS3
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#- - EMAIL to be set

#mymail=andrea.borrelli@cmcc.it
#hsmmail=$mymail #hsm@cmcc.it
#ecmwfmail=$mymail #Adrien.Owono@ecmwf.int
#ccmail=$mymail #silvio.gualdi@cmcc.it

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Machine dependent vars
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
operational_user=cp1
machine=juno
serialq_s=s_short
serialq_l=s_long
parallelq_s=p_short
parallelq_l=p_long
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# DIRS to be set
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if [[ $machine == "zeus" ]]
then
   WORK=/work/csp/`whoami`
   SCRATCHDIR1=/work/csp/${operational_user}/scratch
elif [[ $machine == "juno" ]]
then
   WORK=/work/cmcc/`whoami`
   SCRATCHDIR1=/work/cmcc/${operational_user}/scratch
fi
WORK_SPS4=$WORK/CESM
DIR_ARCHIVE=${WORK_SPS4}/archive
SCRATCHDIR=$WORK/scratch
if [[ $machine == "zeus" ]]
then
   pushdirapec=/data/products/C3S/`whoami`/push_APEC
else
   pushdirapec=/data/delivery/csp/cp1/out/push_APEC
fi
######## WORK DIRS AND PARAMETER FOR C3S 
##nmasks=3
#WORK_C3S=$WORK_SPS4/archive/C3S/
#outdirRSDT=$WORK_SPS4/rsdt/forecast/
#PERTPATH=$DIR_SPS4/triplette_done/

# OTHER
