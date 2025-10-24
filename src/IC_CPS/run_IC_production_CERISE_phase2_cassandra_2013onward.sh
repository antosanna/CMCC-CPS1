#!/bin/sh -l
# HOW TO SUBMIT 
#${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -j run_IC_production_ -l $DIR_LOG/hindcast/ -d $IC_CPS -s run_IC_production_CERISE_phase2.sh 
# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx

np=`${DIR_UTIL}/findjobs.sh -m $machine -n run_IC_production -c yes`
if [[ $np -gt 1 ]]
then
   exit
fi
listmm="2 5 8 11"
for yyyy in {2017..2021}
do
set +euvx
   . ${DIR_UTIL}/descr_ensemble.sh $yyyy
set -euvx
   for mm in $listmm
   do
                         # not 2 digits
      st=`printf '%.2d' $((10#$mm))`   # 2 digits

      mkdir -p $IC_CAM_CPS_DIR/$st
      mkdir -p $IC_CLM_CPS_DIR/$st
      mkdir -p $IC_NEMO_CPS_DIR/$st

      if [[ $yyyy -eq 2015 ]] || [[ $yyyy -eq 2016 ]]
      then
         origdir=/data/products/CERISE-LND-REANALYSIS/transfer/gc02720/RECOVER/stream2015/$yyyy/restart_${yyyy}-$st-01
      elif [[ $yyyy -eq 2017 ]] || [[ $yyyy -eq 2018 ]]
      then
         origdir=/data/products/CERISE-LND-REANALYSIS/transfer/gc02720/RECOVER/stream2017/$yyyy/restart_${yyyy}-$st-01
      elif [[ $yyyy -eq 2019 ]] || [[ $yyyy -eq 2020 ]]
      then
         origdir=/data/products/CERISE-LND-REANALYSIS/transfer/gc02720/RECOVER/stream2019/$yyyy/restart_${yyyy}-$st-01
      elif [[ $yyyy -eq 2021 ]]
      then
         origdir=/data/products/CERISE-LND-REANALYSIS/transfer/gc02720/RECOVER/stream2021/$yyyy/restart_${yyyy}-$st-01


      elif [[ $yyyy -eq 2013 ]]
      then
         origdir=/data/products/CERISE-LND-REANALYSIS/av27223/transfer/restartfiles/2013/restart_${yyyy}-$st-01
      fi
      for ilnd in {01..25}
      do
         actual_ic_clm=$IC_CLM_CPS_DIR/$st/CPS1.clm2.r.$yyyy-$st-01-00000.$ilnd.nc
         actual_ic_hydros=$IC_CLM_CPS_DIR/$st/CPS1.hydros.r.$yyyy-$st-01-00000.$ilnd.nc
         if [[ -f $actual_ic_clm ]] && [[ -f $actual_ic_hydros ]] 
         then
                continue
         fi
         if [[ `ls $origdir/*clm2_00${ilnd}.r.$yyyy-$st* |wc -l ` -eq 0 ]] || [[ `ls $origdir/*hydros_00${ilnd}.r.$yyyy-$st* |wc -l ` -eq 0 ]]
         then
        
            body="restarts not present in $origdir"
            title="CERISE: restart ERROR"
            ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "no" 
            continue
         fi
         rsync -auv $origdir/*clm2_00${ilnd}.r.$yyyy-$st* $IC_CLM_CPS_DIR/$st/
         rsync -auv $origdir/*hydros_00${ilnd}.r.$yyyy-$st* $IC_CLM_CPS_DIR/$st/
         gunzip -f $IC_CLM_CPS_DIR/$st/*.clm2_00${ilnd}.r.$yyyy-$st-01-00000.nc.gz
         gunzip -f $IC_CLM_CPS_DIR/$st/*.hydros_00${ilnd}.r.$yyyy-$st-01-00000.nc.gz
         dim_clm=`ncdump -h $IC_CLM_CPS_DIR/$st/*.clm2_00${ilnd}.r.$yyyy-$st-01-00000.nc|grep "landunit = 2"`
         if [[ $dim_clm =~ "228727" ]] && [[ $yyyy -gt 2014 ]]
         then
            body="Dimensions are $dim_clm while the expected for $yyyy are 228914"
            title="CERISE: restart dims ERROR"
            ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "no" 
         fi
         if [[ $dim_clm =~ "228914" ]] && [[ $yyyy -le 2014 ]]
         then
            body="Dimensions are $dim_clm while the expected for $yyyy are 228727"
            title="CERISE: restart dims ERROR"
            ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "no" 
         fi
         mv $IC_CLM_CPS_DIR/$st/*.clm2_00${ilnd}.r.$yyyy-$st-01-00000.nc $actual_ic_clm
         touch $actual_ic_clm
         mv $IC_CLM_CPS_DIR/$st/*.hydros_00${ilnd}.r.$yyyy-$st-01-00000.nc $actual_ic_hydros
         touch $actual_ic_hydros
         if [[ $yyyy -eq 2007 ]] || [[ $yyyy -eq 2008 ]] || [[ $yyyy -eq 2009 ]] 
         then
            body="$actual_ic_clm $actual_ic_hydros"
            title="CERISE: new ICs preduced for $yyyy$st"
            ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r "no" 
            touch $flag_done
         fi
      
      done
   done   
done   
#
