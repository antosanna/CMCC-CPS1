#!/bin/sh -l
#--------------------------------
#TO BE MODIFED
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh
. $DIR_UTIL/load_cdo

set -evxu

yyyy=$1
set +evxu
. ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -evxu
st=$2

dbg=0  #operational
if [[ `whoami` != "${operational_user}"  ]] ;  then
    dbg=1  #test
fi

dirlog=${DIR_LOG}/$typeofrun/$yyyy$st/diagnostics/
mkdir -p $dirlog
flag_done=$dirlog/plots_all_DONE

echo "launching diagnostic on C3S files for website"
input="$yyyy $st $flag_done $dbg" 
${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_s -S $qos -j FORECAST_C3S_stlist_newproj_notify_$yyyy$st -l $DIR_LOG/$typeofrun/$yyyy$st -d $DIR_DIAG_C3S -s FORECAST_C3S_stlist_newproj_notify.sh -i "$input"

exit
echo "launching ocean diagnostics on DMO for website"
input="$yyyy $st $flag_done $dbg"
${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_m -S $qos -j FORECAST_OCE_stlist_$yyyy$st -l $DIR_LOG/$typeofrun/$yyyy$st -d $DIR_DIAG_C3S -s FORECAST_OCE_stlist.sh -i "$input"

echo "waiting for the diagnostic to be concluded before updating the website"


while `true`
do
  set +e
  nmb_flag=`ls -1 ${flag_done}* |wc -l`
  set -e
  if [ $nmb_flag -eq 17 ] 
  # 8+8 flags from FORECAST_C3S (1 for each variable:prec,t2m,t850,mslp,z500,sst,u200,v200 - seasonal + monthly) 
  #+1 flag from FORECAST_OCE (ocean_profile gif)
  then
      echo "All the diagnostic has been succesfully computed!"
      break
  fi    
  sleep 600 
done
refperiod="${iniy_hind}-${endy_hind}"

if [[ "$machine" == "zeus" ]] && [[ `whoami` == "$operational_user" ]] ; then

   #step 1: link anomaly data from sp1 to sp2  for verifications&co. and send plot png files in $DIR_WEB. This operation is possibble because permissions have been modified to allow sp1 to write on sp2
   #C3S data
   dirplots_final_index="$DIR_WEB/forecast-indexes_dev"
   dirplots_final_map="$DIR_WEB/forecast_dev"
   varlist="mslp z500 t850 t2m precip sst u200 v200"
   for var in $varlist
   do
      #Should be already created - but safer
      mkdir -p ${DIR_FORE_ANOM}/monthly/${var}/C3S/anom/  
      ###links on sp2 needed for evaluation routines!!!
      dirplots=$SCRATCHDIR/diag_C3S/$var/$yyyy$st
      rsync -auv --remove-source-files ${DIR_FORE_ANOM}/monthly/${var}/C3S/anom/${var}_${SPSSystem}_${yyyy}${st}_spread_ano.$refperiod.nc sp2@zeus01.cmcc.scc:/work/csp/sp2/${CPSSYS}/CESM/monthly/${var}/C3S/anom/
      rsync -auv --remove-source-files ${DIR_FORE_ANOM}/monthly/${var}/C3S/anom/${var}_${SPSSystem}_${yyyy}${st}_ens_ano.$refperiod.nc sp2@zeus01.cmcc.scc:/work/csp/sp2/${CPSSYS}/CESM/monthly/${var}/C3S/anom/
      rsync -auv --remove-source-files ${DIR_FORE_ANOM}/monthly/${var}/C3S/anom/${var}_${SPSSystem}_${yyyy}${st}_all_ano.$refperiod.nc sp2@zeus01.cmcc.scc:/work/csp/sp2/${CPSSYS}/CESM/monthly/${var}/C3S/anom/
      if [[ $var ==  "sst" ]] ; then
         rsync -auv --remove-source-files ${DIR_FORE_ANOM}/monthly/${var}/C3S/anom/${var}_${SPSSystem}_${yyyy}${st}_all_ano.${refperiod}_miss.nc sp2@zeus01.cmcc.scc:/work/csp/sp2/${CPSSYS}/CESM/monthly/${var}/C3S/anom/

         rsync -auv $dirplots/${var}_*_${yyyy}_${st}_*_l?.png sp2@zeus01.cmcc.scc:$dirplots_final_map/.
         rsync -auv $dirplots/${var}_*Nino*_*_${yyyy}_${st}.png sp2@zeus01.cmcc.scc:$dirplots_final_index/
         rsync -auv $dirplots/${var}_IOD_*_${yyyy}_${st}.png sp2@zeus01.cmcc.scc:$dirplots_final_index/
      elif [[ $var == "z500" ]] ; then
         rsync -auv $dirplots/hgt500_*_${yyyy}_${st}_*_l?.png sp2@zeus01.cmcc.scc:$dirplots_final_map/.
      else
         rsync -auv $dirplots/${var}_*_${yyyy}_${st}_*_l?.png sp2@zeus01.cmcc.scc:$dirplots_final_map/.
      fi
   done

   #OCE data
   varoce="votemper"
   for var in $varoce
   do
     rsync -auv --remove-source-files $DIR_FORE_ANOM/daily/${var}/anom/${var}_${SPSSystem}_${yyyy}${st}_spread_ano.$refperiod.nc sp2@zeus01.cmcc.scc:/work/csp/sp2/${CPSSYS}/CESM/daily/${var}/anom/
     rsync -auv --remove-source-files $DIR_FORE_ANOM/daily/${var}/anom/${var}_${SPSSystem}_${yyyy}${st}_ens_ano.$refperiod.nc sp2@zeus01.cmcc.scc:/work/csp/sp2/${CPSSYS}/CESM/daily/${var}/anom/
     rsync -auv --remove-source-files $DIR_FORE_ANOM/daily/${var}/anom/${var}_${SPSSystem}_${yyyy}${st}_all_ano.$refperiod.nc sp2@zeus01.cmcc.scc:/work/csp/sp2/${CPSSYS}/CESM/daily/${var}/anom/
    ###this if for now is redundant -  but safer in case new OCN diagnostic will be added in the future
    if [[ $var == "votemper" ]] ; then
       dirplots=$SCRATCHDIR/diag_oce/$var/${yyyy}${st}/
       gifname=$dirplots/temperature_pac_trop_ensmean_${yyyy}_${st}.gif
       dirplots_final="$DIR_WEB/forecast-indexes_dev"
       rsync -auv ${gifname}  sp2@zeus01.cmcc.scc:$dirplots_final/
    fi
   done

   
   #step 3: launch aggiorna_web.sh to publish plots on dev webpage (not to be indented!!!)
ssh sp2@zeus01.cmcc.scc << ENDSSH
cd /users_home/csp/sp2/SPS/CMCC-SPS_FORECAST/
sh aggiorna_web.sh 
ENDSSH

   #step 3: send final mail to Silvio and Stefano
   body="Dear Silvio and Stefano, \n we notify the publication of diagnostics relative to forecast $yyyy$st on the development web-site. \n
   To login: \n
   https://sps-dev.cmcc.it/  \n 
   user: sps-dev \n
   password: jYP8FfYfm65pZd \n \n
   Thank you, \n
   SPS staff\n"

   title="${CPSSYS} forecast notification - Website update"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -c $ccmail
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
   ${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_s -S $qos -B $data2notify -j sendreminder4endForecast${yyyy}${st} -l ${DIR_LOG}/$typeofrun/$yyyy$st -d ${DIR_UTIL} -s sendreminder.sh -i "$input"
   
else
   title="${CPSSYS} forecast notification - C3S diagnostic complete"
   body="Final diagnostic complete. \n Check the notification mails and plots by compute_anomalies_C3S_auto_newproj_notify.sh before sending data to ECMWF.\n
WARNING: PLOTS NOT UPLOADED TO WEBSITE!!!"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
fi 
exit 0
