#!/bin/sh -l

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh


set -eu
st=`date +%m`
yyyy=`date +%Y`
yyIC=`date -d $yyyy${st}'15 - 1 month' +%Y`  # IC year
mmIC=`date -d $yyyy${st}'15 - 1 month' +%m`   # IC month

for pp in 1 2 3 
do
   echo "EDA forcings for perturbation $pp"
   for field in Precip TPHWL Solar
   do
       case $field in
           Precip)var=Prec;;
           Solar)var=Solr;;
           TPHWL)var=TPQWL;;
       esac
       ls -rt $forcDIReda/EDA_n$pp/$field/clmforc.EDA$pp.0.5d.$var.$yyIC-$mmIC.nc
   done
done
