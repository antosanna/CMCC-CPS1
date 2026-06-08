#!/bin/sh -l
#BSUB -J update_SPS4web_plots_from_Leonardo_1
#BSUB -q s_medium
#BSUB -o /work/cmcc/cp1/CPS/CMCC-CPS1/logs/leonardo_transfer/update_SPS4web_plots_from_Leonardo_1.out.%J  
#BSUB -e /work/cmcc/cp1/CPS/CMCC-CPS1/logs/leonardo_transfer/update_SPS4web_plots_from_Leonardo_1.err.%J  
#BSUB -P 0784
#BSUB -M 1000

. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
# First check that no other this script is running
#load module for sshpass
set -uvx


#DIR_WEB=/data/cmcc/cp1/WEB_PLOTS
dirplots_final_index=$DIR_WEB/forecast-indexes_dev
dirplots_final_map=$DIR_WEB/forecast_dev
mkdir -p $dirplots_final_map $dirplots_final_index

yyyy=`date +%Y`
st=`date +%m`
cd $DIR_TEMP
tar -xvf $DIR_TEMP/$yyyy$st.tar 

dirplots=$DIR_TEMP/$yyyy$st

varlist="mslp z500 t850 t2m precip sst u200 v200"
for var in $varlist
do
      if [[ $var ==  "sst" ]] ; then

         rsync -auv $dirplots/${var}_*_${yyyy}_${st}_*_l?.png $dirplots_final_map
         rsync -auv $dirplots/${var}_*Nino*_*_${yyyy}_${st}.png $dirplots_final_index/
         rsync -auv $dirplots/${var}_IOD_*_${yyyy}_${st}.png $dirplots_final_index/
      elif [[ $var == "z500" ]] ; then
         rsync -auv $dirplots/hgt500_*_${yyyy}_${st}_*_l?.png $dirplots_final_map
      else
         rsync -auv $dirplots/${var}_*_${yyyy}_${st}_*_l?.png $dirplots_final_map/.
      fi  
   done

   varoce="toce"
   for var in $varoce
   do
#    ###this if for now is redundant -  but safer in case new OCN diagnostic will be added in the future
    if [[ $var == "toce" ]] ; then
       gifname=$dirplots/temperature_pac_trop_ensmean_${yyyy}_${st}.gif
       rsync -auv ${gifname} $dirplots_final_index
    fi
   done

   $DIR_UTIL/aggiorna_web.sh


