#!/bin/sh -l
#BSUB -J copy_SPS4DMO_from_Cassandra
#BSUB -q s_long
#BSUB -o /work/cmcc/cp1/CPS/CMCC-CPS1/logs/cassandra_transfer/copy_SPS4DMO_from_Cassandra.out.%J  
#BSUB -e /work/cmcc/cp1/CPS/CMCC-CPS1/logs/cassandra_transfer/copy_SPS4DMO_from_Cassandra.err.%J  
#BSUB -P 0784
#BSUB -M 1000

. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -euvx
yyyy=`date +%Y`
st=`date +%m`
DATA_DMO_DIR=/data/cmcc/cp1/temporary/DMO/$yyyy$st
DATA_C3S_DIR=/data/cmcc/cp1/temporary/C3S/$yyyy$st
mkdir -p $DATA_DMO_DIR $DATA_C3S_DIR
# get the list of completed cases (produced daily in cron on Leonardo)
cd $DIR_ARCHIVE
listacasi=`ls sps4_${yyyy}${st}*`
for caso in $listacasi
do
   checkfile_caso=$DATA_DMO_DIR/$caso.copied_to_data
   if [[ -f $checkfile_caso ]]
   then
      continue
   fi
   rsync -auv $DIR_ARCHIVE/sps4_${yyyy}${st}* $DATA_DMO_DIR
   touch $checkfile_caso
done

checkfileC3S=$DATA_C3S_DIR/C3S.$yyyy$st.copied_to_data
if [[ -f $checkfileC3S ]]
then
   exit 0
fi
rsync -auv $WORK_C3S/${yyyy}${st} $DATA_C3S_DIR
touch $checkfileC3S
