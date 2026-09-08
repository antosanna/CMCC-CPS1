#!/bin/sh -l
#BSUB -J copy_webdiags_fore_anom_from_dataCassandra
#BSUB -q s_medium
#BSUB -o /work/cmcc/cp1/CPS/CMCC-CPS1/logs/forecast/copy_webdiags_fore_anom_from_dataCassandra.out.%J  
#BSUB -e /work/cmcc/cp1/CPS/CMCC-CPS1/logs/forecast/copy_webdiags_fore_anom_from_dataCassandra.err.%J  
#BSUB -P 0784
#BSUB -M 1000

. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -uvx

# First check that no other this script is running
#job_run=`$DIR_UTIL/findjobs.sh -m $machine -n copy_webdiags_fore_anom_from_dataCassandra -c yes`
#if [[ $job_run -gt 1 ]]
#then
#   exit 0
#fi

yyyy=`date +%Y`
st=`date +%m`

if [[ ! -f /data/cmcc/cp1/temporary/forecast_plots//copy_plots4web_and_anom_DONE_to_data_Cassandra_${yyyy}${st} ]]
then
   exit
fi

dirplot=$SCRATCHDIR/diag_C3S/forecast_plots/
mkdir -p $dirplot
touchfile=${dirplot}/copy_plots4web_${yyyy}${st}_fore_anom_DONE

if [[ -f $touchfile ]] 
then
   exit 0
fi


dirplot_data=/data/cmcc/cp1/temporary/forecast_plots/$yyyy$st

dirplots_final_index="$DIR_WEB/forecast-indexes_dev"
dirplots_final_map="$DIR_WEB/forecast_dev"

rsync -auv ${dirplot_data} $dirplot


varlist="mslp z500 t850 t2m precip sst u200 v200" #per il momento escludiamo mrlsl+prw
for var in $varlist
do  
    if [[ $var ==  "sst" ]] ; then

         rsync -auv $dirplot/${yyyy}${st}/${var}_*_${yyyy}_${st}_*_l?.png $dirplots_final_map/.
         rsync -auv $dirplot/${yyyy}${st}/${var}_*Nino*_*_${yyyy}_${st}.png $dirplots_final_index/
         rsync -auv $dirplot/${yyyy}${st}/${var}_IOD_*_${yyyy}_${st}.png $dirplots_final_index/
      elif [[ $var == "z500" ]] ; then
         rsync -auv $dirplot/${yyyy}${st}/hgt500_*_${yyyy}_${st}_*_l?.png $dirplots_final_map/.
      else
         rsync -auv $dirplot/${yyyy}${st}/${var}_*_${yyyy}_${st}_*_l?.png $dirplots_final_map/.
      fi  
done

#   #OCE data
varoce="toce"
for var in $varoce
do  
#    ###this if for now is redundant -  but safer in case new OCN diagnostic will be added in the future
  if [[ $var == "toce" ]] ; then
    gifname=$dirplot/${yyyy}${st}/temperature_pac_trop_ensmean_${yyyy}_${st}.gif
    dirplots_final=$dirplots_final_index
    rsync -auv ${gifname} $dirplots_final/
  fi  
done




$DIR_UTIL/aggiorna_web.sh

body="Dear all, \n we notify the publication of diagnostics relative to forecast $yyyy$st on the development web-site. \n
To login: \n
https://sps-dev.cmcc.it/  \n 
user: sps-dev \n
password: jYP8FfYfm65pZd \n \n
Thank you, \n
SPS staff\n"

title="${SPSSystem} forecast notification - Website updated"
${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r yes -s $yyyy$st -c $ccmail -g yes

#last but not least, copy $DIR_FORE_ANOM/${yyyy}${st} for evaluaion and later offline analysis 
DIR_FORE_ANOM_DATA=/data/cmcc/cp1/temporary/fore_anom
mkdir -p $DIR_FORE_ANOM_DATA
rsync -auv ${DIR_FORE_ANOM_DATA}/$yyyy$st $DIR_FORE_ANOM/.

touch ${touchfile}
