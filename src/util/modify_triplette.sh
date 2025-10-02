#!/bin/sh -l

#THIS WORKS ONLY FROM LSF
#${DIR_UTIL}/submitcommand.sh -m $machine -q $serialq_l -j modify_triplette_sps4 -l ${DIR_LOG}/hindcast/ -d ${DIR_UTIL} -s modify_triplette.sh

# load variables from descriptor
. $HOME/.bashrc
. ${DIR_UTIL}/descr_CPS.sh

casefromoutside=$1

set -euxv

dateymdhms=`date +%Y%m%d%H%M%S`
subm_cnt=0
listacasisubmitted=() 
clean_cnt=0
listacasicleaned=() 

#listcases="${SPSSystem}_200311_016" 
#listcases="${SPSSystem}_200011_016" 
#listcases="${SPSSystem}_200611_004"
#listcases="${SPSSystem}_200111_016 ${SPSSystem}_200311_017 ${SPSSystem}_200511_030"
listcases="${SPSSystem}_199410_018 ${SPSSystem}_199910_029 ${SPSSystem}_200110_005"
if [ "$casefromoutside" != "" ]
then
  listcases=$casefromoutside
fi
for caso in $listcases
do
   yyyy=`echo $caso|cut -d '_' -f2|cut -c1-4`
   . $DIR_UTIL/descr_ensemble.sh $yyyy
   st=`echo $caso|cut -d '_' -f2|cut -c5-6`
   ens=`echo $caso|cut -d '_' -f3`
   n1=$((10#$ens))
   n2=$((${nmax4modify_trip} + 1))

   #the line used to modify the IC will be kept to 40($nmax4modify_trip) instead of $nrunmax in hindcast in order to avoid the risk
   #of running twice the same members for the startdates initially launched with 40 members, which have potentially run already 
   #some members between 31 and 40
   #in forecast $nmax4modify_trip will be equal to $nrunmax
   
   if [[ $machine != "leonardo" ]] ; then
      while `true`
      do
         np=`${DIR_UTIL}/findjobs.sh -m $machine -n modify_triplette_${SPSSystem} -c yes`
         if [ $np -eq 1 ]
         then
            break
         fi
         sleep 30
      done
   fi

   if [ ! -f $TRIP_DIR/triplette.CERISE.random.${yyyy}${st}.txt.orig ]
   then
      cp $TRIP_DIR/triplette.CERISE.random.${yyyy}${st}.txt $TRIP_DIR/triplette.CERISE.random.${yyyy}${st}.txt.orig
   else
      cp $TRIP_DIR/triplette.CERISE.random.${yyyy}${st}.txt $TRIP_DIR/triplette.CERISE.random.${yyyy}${st}.txt.$dateymdhms
   fi

   cd $TRIP_DIR

  
   line1=`cat triplette.CERISE.random.${yyyy}${st}.txt | head -n${n1} | tail -1`
   line1script=`echo $line1 | awk '{print $3" "$1" "$2}'`
   line2=`cat triplette.CERISE.random.${yyyy}${st}.txt | head -n${n2} | tail -1`
   line2script=`echo $line2 | awk '{print $3" "$1" "$2}'`
  
  
   #line2 is the order of tirplette file ($1 - lnd, $2 - oce, $3 - atm)
   #line2script is the order of submission script (atm, lnd, oce)
   #retrieveing tag of new ICs to check for their presence
  
   ppatmold=`echo $line1 | awk '{print $3}'`
   pplndold=`echo $line1 | awk '{print $1}'`
   ppoceold=`echo $line1 | awk '{print $2}'`   
   ppatmnew=`echo $line2 | awk '{print $3}'`
   pplndnew=`echo $line2 | awk '{print $1}'`
   ppocenew=`echo $line2 | awk '{print $2}'`     
   ppatmnew2d=`printf '%.2d' $ppatmnew`
   pplndnew2d=`printf '%.2d' $pplndnew`
   ppocenew2d=`printf '%.2d' $ppocenew`  

   echo $n1" line1: "$line1" line1script: "$line1script 
   echo $n2" line2: "$line2" line2script: "$line2script 

   # Make substitutions in triplette.CERISE.random
   # substitute triplette.CERISE with the ones in 41st line
   sed -i "${n1}s/${line1}/${line2}/" triplette.CERISE.random.${yyyy}${st}.txt
   #sed -i "s/${line1}/${line2}/g" triplette.CERISE.random.${yyyy}${st}.txt
   # remove 41st line to avoid repetition in next substitutions
   sed -i "${n2},${n2}d" triplette.CERISE.random.${yyyy}${st}.txt

   # Make substitutions in ensemble scripts
   if [[ $machine == "leonardo" ]]
   then
      cd $DIR_SUBM_SCRIPTS/${st}/${yyyy}${st}_scripts/CINECA
   else
      cd $DIR_SUBM_SCRIPTS/${st}/${yyyy}${st}_scripts/ 
   fi
   if [ ! -f ensemble4_${yyyy}${st}_${ens}.sh.orig ]
   then
      cp ensemble4_${yyyy}${st}_${ens}.sh ensemble4_${yyyy}${st}_${ens}.sh.orig
   else
      cp ensemble4_${yyyy}${st}_${ens}.sh ensemble4_${yyyy}${st}_${ens}.sh.$dateymdhms
   fi
   if [[ $machine == "leonardo" ]] ; then
      #s/YYYY/1994/g;s/STDATE/11/g;s/PATM/9/g;s/PLAND/2/g;s/POCE/3/g;s/NRUN/14/g;
      line1script_leo="s/PATM/${ppatmold}/g;s/PLAND/${pplndold}/g;s/POCE/${ppoceold}/g"
      line2script_leo="s/PATM/${ppatmnew}/g;s/PLAND/${pplndnew}/g;s/POCE/${ppocenew}/g"
      sed -i "s@${line1script_leo}@${line2script_leo}@g" ensemble4_${yyyy}${st}_${ens}.sh
   else
      sed -i "s/${yyyy} ${st} ${line1script}/${yyyy} ${st} ${line2script}/g" ensemble4_${yyyy}${st}_${ens}.sh
      #sed -i "s/${line1script}/${line2script}/g" ensemble4_${yyyy}${st}_${ens}.sh
   fi
   chmod 744 ensemble4_${yyyy}${st}_${ens}.sh
  
   #now everything is ready to submit the modified triplette.CERISE caso, before submission check for presence of ICs
   clmICfile=${IC_CLM_CPS_DIR}/${st}/${CPSSYS}.clm2.r.${yyyy}-${st}-01-00000.${pplndnew2d}.nc
   rofICfile=${IC_CLM_CPS_DIR}/${st}/${CPSSYS}.hydros.r.${yyyy}-${st}-01-00000.${pplndnew2d}.nc
   atmICfile=${IC_CAM_CPS_DIR1}/${st}/${CPSSYS}.cam.i.${yyyy}-${st}-01-00000.${ppatmnew2d}.nc
   nemoICfile=${IC_NEMO_CPS_DIR1}/${st}/${CPSSYS}.nemo.r.${yyyy}-${st}-01-00000.${ppocenew2d}.nc
   iceICfile=${IC_CICE_CPS_DIR1}/${st}/${CPSSYS}.cice.r.${yyyy}-${st}-01-00000.${ppocenew2d}.nc
   if [[ -f $clmICfile ]] && [[ -f $rofICfile ]] && [[ -f $atmICfile ]] && [[ -f $nemoICfile ]] && [[ -f $iceICfile ]] ; then  
     
   #if all the ICs are present resubmit the case
       if [[ $machine == "leonardo" ]] ; then
            mkdir -p $SCRATCHDIR/cases_${st}
            ./ensemble4_${yyyy}${st}_${ens}.sh >& $SCRATCHDIR/cases_${st}/ensemble4_${yyyy}${st}_${ens}.log
       else
          ./ensemble4_${yyyy}${st}_${ens}.sh
       fi
       subm_cnt=$(( $subm_cnt + 1 ))
       listacasisubmitted+="$caso "
   else
      #otherwise clean_caso so that the automatic procedure for hindcast submission will resubmit it as soon as the ICs are ready
      ${DIR_UTIL}/clean_caso.sh $caso
      clean_cnt=$(( $clean_cnt + 1 ))
      listacasicleaned+="$caso "
   fi

done

if [[ ${clean_cnt} -ne 0 ]]
then
   body="In ${dateymdhms} cleaned ${clean_cnt} cases that aborted after changing tripletta, but not resubmitted because of missing ICs: \n
   \n
   ${listacasicleaned[@]} \n
   "
   title="[$CPSSYS] warning - jobs cleaned by modify_triplette.sh"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $yyyy$st
fi

# ***************************************************
# Email and exit
# ***************************************************
if [ "$casefromoutside" == "" ]
then
   body="In ${dateymdhms} re-submitted ${subm_cnt} cases that aborted after changing tripletta: \n
   \n
   ${listacasisubmitted[@]} \n
   "
   title="RECOVER JOBS RE-SUBMITTED"
   ${DIR_UTIL}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title" -r $typeofrun -s $yyyy$st

   echo "Done."
fi
exit 0
