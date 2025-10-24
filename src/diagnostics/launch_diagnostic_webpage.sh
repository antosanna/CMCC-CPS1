#!/bin/sh -l
#--------------------------------

. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. $DIR_UTIL/load_cdo

set -evxu

yyyy=$1
st=$2

set +euvx
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -evxu

dbg=0  #operational
if [[ `whoami` != "${operational_user}"  ]] ;  then
    dbg=1  #test
fi

dirlog=${DIR_LOG}/$typeofrun/$yyyy$st/diagnostics/
mkdir -p $dirlog
flag_done=$dirlog/plots_all_DONE

echo "launching diagnostic on C3S files for website"
input="$yyyy $st $flag_done $dbg" 
${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_s -r $sla_serialID -S $qos -j FORECAST_C3S_stlist_newproj_notify_$yyyy$st -l $DIR_LOG/$typeofrun/$yyyy$st -d $DIR_DIAG_C3S -s FORECAST_C3S_stlist_newproj_notify.sh -i "$input"

echo "launching ocean diagnostics on DMO for website"
input="$yyyy $st $flag_done $dbg"
${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -r $sla_serialID -S $qos -j FORECAST_OCE_stlist_$yyyy$st -l $DIR_LOG/$typeofrun/$yyyy$st -d $DIR_DIAG_C3S -s FORECAST_OCE_stlist.sh -i "$input"

echo "waiting for the diagnostic to be concluded before updating the website"


while `true`
do
  set +e
  nmb_flag=`ls -1 ${flag_done}* |wc -l`
  set -e
  if [ $nmb_flag -eq 17 ]  #per il momento escludiamo mrlsl+prw
  # 10+10 flags from FORECAST_C3S (1 for each variable:prec,prw,mrlsl,t2m,t850,mslp,z500,sst,u200,v200 - seasonal + monthly) 
  #+1 flag from FORECAST_OCE (ocean_profile gif)
  then
      echo "All the diagnostic has been succesfully computed!"
      break
  fi    
  sleep 600 
done
refperiod="${iniy_hind}-${endy_hind}"

if [[ "$machine" == "juno" ]] && [[ `whoami` == "$operational_user" ]] ; then

   #step 1: link anomaly data from sp1 to sp2  for verifications&co. and send plot png files in $DIR_WEB. This operation is possibble because permissions have been modified to allow sp1 to write on sp2
   #C3S data
   dirplots_final_index="$DIR_WEB/forecast-indexes_dev"
   dirplots_final_map="$DIR_WEB/forecast_dev"
   varlist="mslp z500 t850 t2m precip sst u200 v200" #per il momento escludiamo mrlsl+prw
   for var in $varlist
   do
      #Should be already created - but safer
      mkdir -p ${DIR_FORE_ANOM}/monthly/${var}/C3S/anom/  
      ###links on sp2 needed for evaluation routines!!!
      dirplots=$SCRATCHDIR/diag_C3S/forecast_plots/$yyyy$st
      if [[ $var ==  "sst" ]] ; then

         rsync -auv $dirplots/${var}_*_${yyyy}_${st}_*_l?.png $dirplots_final_map/.
         rsync -auv $dirplots/${var}_*Nino*_*_${yyyy}_${st}.png $dirplots_final_index/
         rsync -auv $dirplots/${var}_IOD_*_${yyyy}_${st}.png $dirplots_final_index/
      elif [[ $var == "z500" ]] ; then
         rsync -auv $dirplots/hgt500_*_${yyyy}_${st}_*_l?.png $dirplots_final_map/.
      else
         rsync -auv $dirplots/${var}_*_${yyyy}_${st}_*_l?.png $dirplots_final_map/.
      fi
   done

#   #OCE data
   varoce="toce"
   for var in $varoce
   do
#    ###this if for now is redundant -  but safer in case new OCN diagnostic will be added in the future
    if [[ $var == "toce" ]] ; then
       dirplots=$SCRATCHDIR/diag_oce/$var/${yyyy}${st}/
       gifname=$dirplots/temperature_pac_trop_ensmean_${yyyy}_${st}.gif
       dirplots_final=$dirplots_final_index
       rsync -auv ${gifname} $dirplots_final/
    fi
   done

   
   #step 3: launch aggiorna_web.sh to publish plots on dev webpage (not to be indented!!!)
   $DIR_UTIL/aggiorna_web.sh 

   #step 3: send final mail to Silvio and Stefano
   body="Dear all, \n we notify the publication of diagnostics relative to forecast $yyyy$st on the development web-site. \n
   To login: \n
   https://sps-dev.cmcc.it/  \n 
   user: sps-dev \n
   password: jYP8FfYfm65pZd \n \n
   Thank you, \n
   SPS staff\n"

   title="${SPSSystem} forecast notification - Website updated"
   #${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -c $ccmail
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r yes -s $yyyy$st -c $ccmail
   y2notify=`date +%Y`
   m2notify=`date +%m`
   d2notify=`date +%d`
   H2notify=`date +%H`
   M2notify=`date +%M`
   hourincrement=3
   y2notify=$( $DIR_UTIL/getincrdate.sh 1 $hourincrement );
   m2notify=$( $DIR_UTIL/getincrdate.sh 2 $hourincrement );
   d2notify=$( $DIR_UTIL/getincrdate.sh 3 $hourincrement );
   H2notify=$( $DIR_UTIL/getincrdate.sh 4 $hourincrement );
   M2notify=$( $DIR_UTIL/getincrdate.sh 5 $hourincrement );
   data2notify=$y2notify":"$m2notify":"$d2notify":"$H2notify":"$M2notify
   input="8"
   ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_s -r $sla_serialID -S $qos -B $data2notify -j sendreminder4endForecast${yyyy}${st} -l ${DIR_LOG}/$typeofrun/$yyyy$st -d ${DIR_UTIL} -s sendreminder.sh -i "$input"
   
else
   title="${SPSSystem} forecast notification - C3S diagnostic complete"
   body="Final diagnostic complete. \n Check the notification mails and plots by compute_anomalies_C3S_auto_newproj_notify.sh before sending data to ECMWF.\n
WARNING: PLOTS NOT UPLOADED TO WEBSITE!!!"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r yes -s $yyyy$st
fi 
exit 0
