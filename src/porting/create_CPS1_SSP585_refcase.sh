#!/bin/sh -l

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh

caso=${CPSSYS}_SSP585_reference
if [[ $machine == "cassandra" ]]
then
   caso=${CPSSYS}_SSP585_reference_esmf8.4
fi

if [[ -d $DIR_CASES/$caso ]]
then
   rm -rf $DIR_CASES/$caso
fi

#load modules in leonardo
if [[ $machine == "leonardo" ]]
then
   module use -p $modpath
fi
if [[ $machine == "cassandra" ]]
then
   . ~/load_conda 
fi
conda activate $envcondacm3

$DIR_CESM/cime/scripts/create_newcase --case $DIR_CASES/$caso --compset SSP585_CAM60%WCSC_CLM51%BGC-CROP_CICE_NEMO_HYDROS_SGLC_SWAV --res f05_n0253 --driver nuopc --mach $machine --run-unsupported

cd $DIR_CASES/$caso

./xmlchange STOP_OPTION=nmonths
if [[ $machine == "cassandra" ]]
then
   ./xmlchange NTASKS_ATM=-3
   ./xmlchange NTASKS_CPL=-3
   ./xmlchange NTASKS_OCN=330
   ./xmlchange NTASKS_ICE=-3
   ./xmlchange NTASKS_ROF=-3
   ./xmlchange NTASKS_LND=-3
elif [[ $machine == "juno" ]]
then
   ./xmlchange NTASKS_ATM=-4
   ./xmlchange NTASKS_CPL=-4
   ./xmlchange NTASKS_OCN=279
   ./xmlchange NTASKS_ICE=-4
   ./xmlchange NTASKS_ROF=-4
   ./xmlchange NTASKS_LND=-4
   ./xmlchange PIO_STRIDE=18
elif [[ $machine == "leonardo" ]]
then
# hardcoded because we cannot use the entire node (112 cores) due to
# memory issues (we will ask 3 nodes)
   ./xmlchange NTASKS_ATM=288
   ./xmlchange NTASKS_CPL=288
   ./xmlchange NTASKS_OCN=279
   ./xmlchange NTASKS_ICE=288
   ./xmlchange NTASKS_ROF=288
   ./xmlchange NTASKS_LND=288
   ./xmlchange PIO_STRIDE=-99
# this var must be set as -99 because with any other value the model does not run
fi
./xmlchange NTASKS_WAV=1
./xmlchange NTASKS_GLC=1
./xmlchange NTASKS_ESP=1
./xmlchange ROOTPE_ROF=0
./xmlchange ROOTPE_ICE=0
./xmlchange ROOTPE_OCN=0
./xmlchange CAM_CONFIG_OPTS="-phys cam_dev -chem waccm_sc_mam4 -nlev 83"
./xmlchange RESUBMIT=1
./xmlchange CLM_FORCE_COLDSTART=off
./xmlchange ROF_NCPL=8
./xmlchange CHARGE_ACCOUNT=0490
./xmlchange PROJECT=0490
./xmlchange STOP_N=1
./xmlchange RUN_TYPE=hybrid
./xmlchange --force --subgroup case.run JOB_QUEUE=$parallelq_l
./xmlchange --subgroup case.run JOB_WALLCLOCK_TIME=08:00

./case.setup --reset
if [[ $machine == "leonardo" ]] ; then
   rsync -av $DIR_TEMPL/env_mach_specific.xml_${env_workflow_tag} $DIR_CASES/$caso/env_mach_specific.xml
fi
./case.setup


cat > user_nl_cam << EOF1
inithist = 'NONE'
ncdata = '\$DIN_LOC_ROOT/atm/cam/inic/fv/cami_0000-01-01_0.47x0.63_L83_c230109.nc'
effgw_beres_dp         = 0.55D0
gw_qbo_hdepth_scaling  = 0.25D0
qbo_use_forcing        = .false.
frontgfc               = 2.7D-15
taubgnd                = 2.5D-3
effgw_rdg_beta = 0.75D0
effgw_rdg_beta_max = 0.75D0
tau_0_ubc=.true.
ubc_specifier = 'Q->2.d-10vmr'
gw_apply_tndmax          = .false.
gw_limit_tau_without_eff = .true.
gw_lndscl_sgh            = .false.
gw_oro_south_fac         = 2.d0
fv_nsplit   =            18
fv_nspltrac =            9
fv_nspltvrm =            9
fv_filtcw = 1
mfilt=1,1460,730,365,2920,
nhtfrq = 0,-6,-12,-24,-3
avgflag_pertape='A','I','I','A','I',
empty_htapes=.true.,
fexcl1=''
fincl1 = 'CLDTOT','LHFLX','SHFLX','QREFHT','PRECT','PRECTMX:X',
         'PRECSC','PRECSL','PS',
         'PSL','FLDS','FLNS','FLUT','FLUTC','FSDS','FSNTOA','FSNS',
         'FSUTOA','FSNTOAC','U10','TREFHT','WSPDSRFMX:X','TREFHT',
         'TREFHTMX:X','TREFHTMN:M','TAUX','TAUY','TS','VBOT','UBOT',
         'OMEGA1000',
         'OMEGA925','OMEGA850','OMEGA700','OMEGA500','OMEGA400','OMEGA300','OMEGA250',
         'OMEGA200','OMEGA100','OMEGA050','OMEGA030','OMEGA020','OMEGA010',
         'Q1000','Q925','Q850','Q700','Q500','Q400','Q300','Q250',
         'Q200','Q100','Q050','Q030','Q020','Q010',
         'T1000','T925','T850','T700','T500','T400','T300','T250',
         'T200','T100','T050','T030','T020','T010',
         'U1000','U925','U850','U700','U500','U400','U300','U250',
         'U200','U100','U050','U030','U020','U010',
         'V1000','V925','V850','V700','V500','V400','V300','V250',
         'V200','V100','V050','V030','V020','V010',
         'Z1000','Z925','Z850','Z700','Z500','Z400','Z300','Z250',
         'Z200','Z100','Z050','Z030','Z020','Z010',
         'LANDFRAC','PHIS',
fincl2 = 'TREFHT','RHREFHT','UBOT','VBOT','PSL','CLDTOT','CLDLOW','U10','TS',
         'ICEFRAC','SST','LANDFRAC','T300',
         'T500','Q850','Q700','Z500','TMQ','OMEGA500','WSPDSRFMX:X',
         'FLNT','U850','V850','U700','V700','U250','V250','PRECT',
         'U200','V200','T850',
fincl3 = 'Q1000','Q925','Q850','Q700','Q500','Q400','Q300',
         'Q200','Q100','Q050','Q030','Q010',
         'OMEGA1000','OMEGA925','OMEGA850','OMEGA700','OMEGA500',
         'OMEGA400','OMEGA300',
         'OMEGA200','OMEGA100','OMEGA050','OMEGA030','OMEGA010',
         'T1000','T925','T850','T700','T500','T400','T300',
         'T200','T100','T050','T030','T010',
         'U1000','U925','U850','U700','U500','U400','U300','U250',
         'U200','U100','U050','U030','U010',
         'V1000','V925','V850','V700','V500','V400','V300',
         'V200','V100','V050','V030','V010',
         'Z1000','Z925','Z850','Z700','Z500','Z400','Z300',
         'Z200','Z100','Z050','Z030','Z010',
fincl4 = 'ICEFRAC','PRECC','PRECT','PRECSL','PRECSC','SHFLX','LHFLX',
         'FSDS','FLDS','FLNS','FSNS','FLNT','FSNT',
         'TAUX','TAUY','QFLX','FSNTOA','TS',
         'TREFMXAV:X','TREFMNAV:M','SOLIN',
         'Z500','V850','U850','T850','VBOT','UBOT','TREFHT','RHREFHT',
         'WSPDSRFMX:X','U10','FSDS','PSL','PRECTMX:X','PRECT','TMQ' ,
fincl5 = 'TS','CLDTOT',
fincl7 = '',
do_circulation_diags=.false.

EOF1

cat > user_nl_clm << EOF2
flanduse_timeseries = '\$DIN_LOC_ROOT/lnd/clm2/surfdata_map/landuse.timeseries_0.47x0.63_SSP5-8.5_16pfts_Irrig_CMIP6_simyr1850-2100_c231218.nc'
fsurdat = '\$DIN_LOC_ROOT/lnd/clm2/surfdata_map/surfdata_0.47x0.63_SSP5-8.5_16pfts_Irrig_CMIP6_simyr1850_c231218.nc'
hist_empty_htapes=.true.
hist_mfilt = 1,365,1460,365
hist_nhtfrq = 0, -24,-6,-24,
hist_avgflag_pertape = ' ','A','I','I',
hist_fincl1 = 'SOILLIQ', 'QVEGT', 'H2OSNO', 'TLAI', 'FSNO', 'SOILWATER_10CM', 'SOILICE','QRUNOFF', 'QDRAI', 'SNOWDP','QSOIL','QVEGE'
hist_fincl2 = 'H2OSNO','SNOWDP','QOVER','QDRAI','H2OSOI','QFLX_SNOW_GRND','TBOT','SOILLIQ','SOILICE',
hist_fincl3 = 'H2OSOI','TSOI','SNOTTOPL',
hist_fincl4 = 'FSNO','Z0MG','Z0MV','Z0QG','Z0QV','Z0HG','Z0HV','TLAI'
urban_hac = 'OFF'

!SNOW OPTIONS
reset_snow = .true.
h2osno_max = 10000.0
lotmp_snowdensity_method = 'TruncatedAnderson1976'
wind_dependent_snow_density = .false.

!use_init_interp = .true.
EOF2

echo "ice_runoff = .false." >> user_nl_hydros


cat > user_nl_cice << EOF3
ndtd = 2
histfreq = 'm',
histfreq_n = 1,
f_aice = "m",
f_hi = "m",
f_hs = "m",
f_tsfc = "m",
f_uvel = "m",
f_vvel = "m",
f_strairx = "m",
f_strairy = "m"
EOF3

