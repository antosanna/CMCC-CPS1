#!/bin/sh -l

#set -euvx
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh


set -eu
t_analysis=00
st=`date +%m`
yyyy=`date +%Y`
yyIC=`date -d $yyyy${st}'15 - 1 month' +%Y`  # IC year
mmIC=`date -d $yyyy${st}'15 - 1 month' +%m`   # IC month
dd=`$DIR_UTIL/days_in_month.sh $mmIC $yyIC`    # IC day
for pp in 0 1 2 3 4 5 6 7 8 9
do
   echo "EDA raw for perturbation $pp"
   inputECEDA=$DATA_ECACCESS/EDA/snapshot/${t_analysis}Z/ECEDA${pp}_$yyIC$mmIC${dd}_${t_analysis}.grib
   ls -rt $inputECEDA
done
