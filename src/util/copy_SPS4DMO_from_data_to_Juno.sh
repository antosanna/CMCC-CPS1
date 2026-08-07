#!/bin/sh -l
#BSUB -J copy_SPS4DMO_from_data
#BSUB -q s_long
#BSUB -o /work/cmcc/cp1/CPS/CMCC-CPS1/logs/cassandra_transfer/copy_SPS4DMO_from_data.out.%J  
#BSUB -e /work/cmcc/cp1/CPS/CMCC-CPS1/logs/cassandra_transfer/copy_SPS4DMO_from_data.err.%J  
#BSUB -P 0784
#BSUB -M 1000

. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -euvx
yyyy=`date +%Y`
st=`date +%m`

ncopy_run=`$DIR_UTIL/findjobs.sh -m $machine -n copy_SPS4DMO_from_data_to_Juno -c yes`
if [[ $ncopy_run -gt 1 ]]
then
   exit 0 
fi
DATA_DMO_DIR=/data/cmcc/cp1/temporary/DMO/$yyyy$st
DATA_C3S_DIR=/data/cmcc/cp1/temporary/C3S/$yyyy$st
# get the list of completed cases (produced daily in cron on Leonardo)
if [[ ! -d $DATA_DMO_DIR ]]
then
   echo "this forecast has not been run on Cassandra"
   exit 0
fi
cd $DATA_DMO_DIR
listacasi=`ls | grep sps4_${yyyy}${st}`
for caso in $listacasi
do
   checkfile_caso=$DATA_DMO_DIR/$caso.copied_to_data
   if [[ -f $checkfile_caso ]]
   then
      checkfile_caso_copied=$DIR_ARCHIVE/$caso.copied_from_data
      rsync -auv $DATA_DMO_DIR/sps4_${yyyy}${st}_0?? $DIR_ARCHIVE
      touch $checkfile_caso_copied
   fi
done

checkfileC3S=$DATA_C3S_DIR/C3S.$yyyy$st.copied_to_data
if [[ -f $checkfileC3S ]]
then
   checkfileC3S_copied=$DATA_C3S_DIR/C3S.$yyyy$st.copied_from_data
   rsync -auv $DATA_C3S_DIR/${yyyy}${st} $WORK_C3S
   touch $checkfileC3S_copied
fi
