#!/usr/bin/sh -l
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_nco
# activate needed env
#TEMPORARY
if [[ $machine -ne "juno" ]]
then
   echo "we cannot run this script here because files are in Juno"
   exit
fi
set -v
conda activate $envcondanemo
set -euvx    # keep this instruction after conda activation
#INPUT:
yyyy=$1
st=$2
poce=$3
poce1=$((10#$(($poce - 1))))
yy_assim=`date -d ' '$yyyy${st}15' - 1 month' +%Y`
mm_assim=`date -d ' '$yyyy${st}15' - 1 month' +%m`
# add your frequencies and grids. The script skip them if not present
case $poce1 in
   0) OUTDIR=$DIR_REST_OIS/SLAMB$poce1/MONTHLY_RESTARTS/${yy_assim}${mm_assim}/;;
   1) OUTDIR=$DIR_REST_OIS/SLAMB$poce1/MONTHLY_RESTARTS/${yy_assim}${mm_assim}/;;
   2) OUTDIR=$DIR_REST_OIS/MB4/MONTHLY_RESTARTS/${yy_assim}${mm_assim}/;;
   3) OUTDIR=$DIR_REST_OIS/MB5/MONTHLY_RESTARTS/${yy_assim}${mm_assim}/;;
esac
if [[ ! -d $OUTDIR ]]
then
   exit 0
fi
mkdir -p $IC_NEMO_CPS_DIR/$st
TMPNEMOREST=$SCRATCHDIR/nemo_rebuild/restart/$yyyy$st
mkdir -p $TMPNEMOREST
listaf=`ls $OUTDIR/*_restart_0???.nc`
nf=`ls $OUTDIR/*_restart_0???.nc|wc -l`
rootname=`basename $OUTDIR/*_restart_0000.nc|rev|cut -d '_' -f2-|rev`
# find maximum divider
N=`$DIR_UTIL/max_prime_factor.sh $nf`
 
if [[ ! -f $IC_NEMO_CPS_DIR/$st/${CPSSYS}.nemo.r.$yyyy-${st}-01-00000.$poce.nc ]]
then
   cd $TMPNEMOREST
   for ff in $listaf
   do 
      rsync -auv $ff .
   done
   
   mpirun -n $N python -m mpi4py $DIR_NEMO_REBUILD/nemo_rebuild.py -i $TMPNEMOREST/${rootname}
   stat=$?
   if [[ $stat -eq 0 ]]
   then
     # remove DELAY_fwb from OIS restarts
     ncatted -a DELAY_fwb,global,d,, $TMPNEMOREST/${rootname}.nc $IC_NEMO_CPS_DIR/$st/${CPSSYS}.nemo.r.$yyyy-${st}-01-00000.$poce.nc
   fi
fi

if [[ ! -f ${IC_CICE_CPS_DIR}/$st/${CPSSYS}.cice.r.${yyyy}-${st}-01-00000.${poce}.nc ]]
then
   nf_ice=`ls $OUTDIR/*.cice.r.*.nc |wc -l`
   if [[ ${nf_ice} -eq 1 ]] ; then
       listaf_ice=`ls $OUTDIR/*.cice.r.${yyyy}-${st}*.nc`  #19930731_SLAMB1.cice.r.1993-08-01-00000.nc  
       for ff in ${listaf_ice} 
       do
          rsync -auv $ff ${IC_CICE_CPS_DIR}/$st/${CPSSYS}.cice.r.${yyyy}-${st}-01-00000.${poce}.nc 
       done
   fi
fi
