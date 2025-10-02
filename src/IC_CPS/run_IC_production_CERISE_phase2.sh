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
if [[ $machine == "juno" ]]
then
   listmm="2 11"
elif [[ $machine == "cassandra" ]]
then
   listmm="5 8"
fi
for yyyy in {2002..2021}
do
   if [[ $yyyy -eq 2013 ]] 
   then
      continue
   fi
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

      if [[ $yyyy -eq 2007 ]] || [[ $yyyy -eq 2008 ]] || [[ $yyyy -eq 2009 ]] 
      then
         origdir=/data/products/CERISE-LND-REANALYSIS/transfer/gc02720/stream2006/$yyyy/restart_${yyyy}-${st}-01
      elif [[ $yyyy -eq 2019 ]]
      then
         origdir=/data/products/CERISE-LND-REANALYSIS/transfer/gc02720/stream2018/$yyyy/restart_${yyyy}-${st}-01
      else
         if [[ $machine == "juno" ]]
         then
            origdir=/work/cmcc/spreads-lnd/land/archive/SPREADS_MU30/cerise_phase2_restarts/restart_${yyyy}-${st}-01
         elif [[ $machine == "cassandra" ]]
         then
            origdir=/data/cmcc/cp1/temporary/cerise_IC_clm/${st}
         fi
      fi

      for ilnd in {01..25}
      do
         actual_ic_clm=$IC_CLM_CPS_DIR/$st/CPS1.clm2.r.$yyyy-$st-01-00000.$ilnd.nc
         actual_ic_hydros=$IC_CLM_CPS_DIR/$st/CPS1.hydros.r.$yyyy-$st-01-00000.$ilnd.nc
         flag_done=$SCRATCHDIR/newic.$yyyy-$st.$ilnd.done
         if [[ -f $actual_ic_clm ]] && [[ -f $actual_ic_hydros ]] 
         then
             if [[ $yyyy -eq 2007 ]] || [[ $yyyy -eq 2008 ]] || [[ $yyyy -eq 2009 ]] || [[ $yyyy -eq 2019 ]]
             then
                if [[ -f $flag_done ]]
                then
                   continue
                fi
             else
                continue
             fi
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
         if [[ $yyyy -eq 2007 ]] || [[ $yyyy -eq 2008 ]] || [[ $yyyy -eq 2009 ]] || [[ $yyyy -eq 2019 ]]
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
