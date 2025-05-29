#!/bin/sh -l
#BSUB  -J launch_eda_run_offline
#BSUB  -q s_long
#BSUB  -o /work/cmcc/cp1/CPS/CMCC-CPS1/logs/IC_CLM/launch_eda_run_offline.stdout.%J  
#BSUB  -e /work/cmcc/cp1/CPS/CMCC-CPS1/logs/IC_CLM/launch_eda_run_offline.stderr.%J  
#BSUB  -P 0490
#BSUB  -M 500

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

set -euvx

yyyy_in=2025
mm_in=05

newyy=${yyyy_in}                   # year start-date
newmm=${mm_in}                     # month start-date

while [[ ${newyy}${newmm} -le 202505 ]]
do
    
   yyyy=$newyy                # month start-date: this is a number 
   st=`printf '%.2d' $((10#$newmm))`   # 2 digits

   yyyym1=`date -d ' '$yyyy${st}01' - 1 month' +%Y`
   mmm1=`date -d ' '$yyyy${st}01' - 1 month' +%m`

   mkdir -p $IC_CLM_CPS_DIR/$st

   set +euvx
       . ${DIR_UTIL}/descr_ensemble.sh $yyyy
   set -euvx

   nmb_ic_clm=`ls $IC_CLM_CPS_DIR/$st/${CPSSYS}.clm2.r.$yyyy-$st-01-00000.??.nc |wc -l`
   nmb_ic_hyd=`ls $IC_CLM_CPS_DIR/$st/${CPSSYS}.hydros.r.$yyyy-$st-01-00000.??.nc|wc -l`
   echo $yyyy
   echo $st
   if [[ ${nmb_ic_clm} -eq 3 ]] && [[ ${nmb_ic_hyd} -eq 3 ]] 
   then
         echo "advancing without recomputing"
         newmm=`date -d ' '$yyyy${st}01' + 1 month' +%m`
         newyy=`date -d ' '$yyyy${st}01' + 1 month' +%Y`
         continue
   else
      mkdir -p $DIR_LOG/$typeofrun/$yyyy$st/IC_CLM
      for ilnd in {01..03}
      do
         icclm=$IC_CLM_CPS_DIR/$st/${CPSSYS}.clm2.r.$yyyy-$st-01-00000.${ilnd}.nc
         ichydros=$IC_CLM_CPS_DIR/$st/${CPSSYS}.hydros.r.$yyyy-$st-01-00000.${ilnd}.nc

         if [[ -f $icclm ]] && [[ -f $ichydros ]] ; then
            continue
         fi
         echo $ilnd
         clm_err_file=$DIR_LOG/$typeofrun/$yyyy$st/IC_CLM/clm_run_error_touch_EDA${ilnd}.$yyyy$st
         if [[ -f $clm_err_file ]] ; then
	           rm ${clm_err_file}
         fi
         eda_incomplete_check=$DIR_LOG/$typeofrun/$yyyy$st/IC_CLM/EDA${ilnd}_incomplete_${yyyy}$st
         inputlnd="$yyyym1 $mmm1 $ilnd $icclm $ichydros $eda_incomplete_check ${clm_err_file}"
         ${DIR_UTIL}/submitcommand.sh -m $machine -M 3000 -S $qos -t "24" -q $serialq_l -s launch_forced_run_EDA.sh -j launchFREDA${ilnd}_${yyyy}${st} -d ${DIR_LND_IC} -l ${DIR_LOG}/$typeofrun/$yyyy$st/IC_CLM -i "$inputlnd"
         body="CLM: submitted script launch_forced_run_EDA.sh to produce CLM ICs from EDA perturbation $ilnd"
         title="[CLMIC] ${CPSSYS} forecast notification"
         ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"  -r $typeofrun -s $yyyy$st
      done
      while `true`
      do
         sleep 600
         nmb_ic_mv=`ls $DIR_LOG/$typeofrun/${yyyy}${st}/IC_CLM/mv_IC_EDA?_done |wc -l`
         if [[ ${nmb_ic_mv} -eq 3 ]] 
         then
            echo "all the 3 ICs are ready for stdate ${yyyy}${st}"
            break
         fi
      done
      newmm=`date -d ' '$yyyy${st}01' + 1 month' +%m`
      newyy=`date -d ' '$yyyy${st}01' + 1 month' +%Y`
   fi
done
