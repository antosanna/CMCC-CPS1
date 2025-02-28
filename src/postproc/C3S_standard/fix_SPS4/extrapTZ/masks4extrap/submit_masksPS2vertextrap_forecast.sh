#!/bin/sh -l
# create masks for vertinterpZT that will recompute the field where the mask is set to 0
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
set -evxu
here=$PWD
mkdir -p $DIR_LOG/hindcast/masks2PSvertextrapTZ 
for st in 01 02 #10 11 12
do
   for yyyy in {1993..2022}
   do

      input="$yyyy $st"
#      ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -j masksPS2vertextrap_${yyyy}${st} -l $DIR_LOG/hindcast/masks2PSvertextrapTZ -d $here -s masksPS2vertextrap_forecast.sh -i "$input"
#      ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -j masksPS2vertextrap_${yyyy}${st} -l $DIR_LOG/hindcast/masks2PSvertextrapTZ -d $here -s masksPS2vertextrap_forecast_2attempt.sh -i "$input"
#      ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -j masksPS2vertextrap_${yyyy}${st} -l $DIR_LOG/hindcast/masks2PSvertextrapTZ -d $here -s masksPS2vertextrap_forecast_3attempt.sh -i "$input"
      ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -j masksPS2vertextrap_${yyyy}${st} -l $DIR_LOG/hindcast/masks2PSvertextrapTZ -d $here -s masksPS2vertextrap_forecast_4attempt.sh -i "$input"
   exit
   done
done
