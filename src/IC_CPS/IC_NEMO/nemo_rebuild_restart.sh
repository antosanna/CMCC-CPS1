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
conda activate $envcondanemo
set -euvx    # keep this instruction after conda activation
#INPUT:
yyyy=$1
st=$2
poce=$3
poce1=$((10#$(($poce - 1))))
# add your frequencies and grids. The script skip them if not present
OUTDIR=$DIR_REST_OIS/MB$poce1/RESTARTS/$yyyy${st}0100/
mkdir -p $IC_NEMO_SPS_DIR/$st
TMPNEMOREST=$SCRATCHDIR/nemo_rebuild/restart/$yyyy$st
mkdir -p $TMPNEMOREST
listaf=`ls $OUTDIR/*_restart_0???.nc`
nf=`ls $OUTDIR/*_restart_0???.nc|wc -l`
rootname=`basename $OUTDIR/*_restart_0000.nc|rev|cut -d '_' -f2-|rev`
# find maximum divider
N=`$DIR_UTIL/max_prime_factor.sh $nf`
 
cd $TMPNEMOREST
for ff in $listaf
do 
   rsync -auv $ff .
done
mpirun -n $N python -m mpi4py /users_home/csp/as34319/NEMO_REBUILD/py_nemo_rebuild/src/py_nemo_rebuild/nemo_rebuild.py -i $TMPNEMOREST/${rootname}
# remove DELAY_fwb from OIS restarts
ncatted -a DELAY_fwb,global,d,, $TMPNEMOREST/${rootname}.nc $IC_NEMO_SPS_DIR/$st/${CPSSYS}.nemo.$yyyy-${st}-01-00000.$poce.nc

