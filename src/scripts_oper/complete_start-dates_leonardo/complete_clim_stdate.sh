#!/bin/sh -l
. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -euvx
st=05
conda activate $envcondacm3
debug=0
here=$PWD
for yyyy in {2001..2010}
do
   cd $here
   list_casi=`python read_csv.py sps4_hindcast_list.csv -y $yyyy -st $st `
   echo $list_casi
   cd $DIR_SUBM_SCRIPTS/$st/$yyyy${st}_scripts
   for caso in $list_casi
   do 
      i=`echo $caso|cut -d '_' -f3|cut -c 2-3`
      if [[ -d $DIR_CASES/${caso} ]]
      then
         continue
      fi
      if [[ ! -f ensemble4_${yyyy}${st}_0${i}.sh ]]
      then
         echo "`realpath ensemble4_${yyyy}${st}_0${i}.sh` misteriously missing! continue"
         continue
      fi
      ./ensemble4_${yyyy}${st}_0${i}.sh #>& $SCRATCHDIR/cases_${st}/ensemble4_${yyyy}${st}_0${i}.log
      sleep 10
   done
   if [[ $debug -eq 1 ]]
   then
      exit
   fi
done
