#!/bin/sh -l
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
set -euvx
set -euvx
LOG_FILE=$DIR_LOG/tests/launch_mv_IC_2ICDIR_CLM.`date +%Y%m%d%H%M`
exec 3>&1 1>>${LOG_FILE} 2>&1

# all these vars defined above but not yet available
#TEMPORARY
iniy=1993
endy=2003
# END TEMPORARY
for yyyy in `seq $iniy $endy`
do
   . $DIR_UTIL/descr_ensemble.sh $yyyy
   for st in {01..12}
   do  
      mkdir -p $DIR_LOG/$typeofrun/$yyyy$st/IC_CLM
      mkdir -p ${IC_CLM_CPS_DIR}/$st
      for plnd in `seq -w 1 ${n_ic_clm}`
      do  
         input="$yyyy $st $plnd"
         $DIR_UTIL/submitcommand.sh -q s_short -M 2000 -s  mv_IC_2ICDIR.hindcast.sh -i "$input" -d $DIR_LND_IC -j mv_IC_2ICDIR_${yyyy}${st}_${plnd} -l $DIR_LOG/$typeofrun/$yyyy$st/IC_CLM
      done
   done
done
~                             
